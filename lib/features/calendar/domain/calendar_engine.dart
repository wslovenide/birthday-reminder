import 'package:lunar/lunar.dart';

import 'birthday_spec.dart';
import 'calendar_type.dart';
import 'lunar_info.dart';
import 'occurrence.dart';

/// 历法引擎：把「生日规格」换算为下一次公历生日。
///
/// 这是应用的深模块：对外只暴露少量纯函数式接口，内部封装了农历与公历
/// 互转、闰月、大月/小月、腊月无三十、公历 2 月 29 日平年回退、跨年滚动
/// 等全部复杂规则。它不依赖数据库、通知或 UI，可完全隔离测试。
abstract class CalendarEngine {
  /// 计算 [from] 当天或之后最近一次生日。
  Occurrence nextOccurrence(BirthdaySpec spec, DateTime from);

  /// 把公历 [date] 转为农历信息。
  LunarInfo toLunar(DateTime date);

  /// 校验生日规格是否合法。
  bool isValid(BirthdaySpec spec);

  /// 生日的展示文案，如「农历五月初五」「公历5月5日」。
  String specLabel(BirthdaySpec spec);

  /// 公历某年某月的天数。
  int solarMonthDays(int year, int month);

  /// 生日在公历 [solarYear] 年内发生的日期；该年不发生时为 null。
  ///
  /// 与 [nextOccurrence] 不同，本方法固定年份，用于「今年已过/未过」统计。
  DateTime? birthdayInSolarYear(BirthdaySpec spec, int solarYear);

  /// 已知出生年份时，返回出生当天的公历日期；未填写出生年份时返回 null。
  ///
  /// 农历生日的年份按农历年解释，腊月出生等跨公历年的情况会返回次年的日期。
  DateTime? birthDate(BirthdaySpec spec);

  /// 农历某年某月的天数；该月不存在（如该年无此闰月）时返回 0。
  int lunarMonthDays(int lunarYear, int month, {bool leapMonth = false});

  /// 农历 [lunarYear] 年的闰月，无则为 0。
  int leapMonthOf(int lunarYear);
}

/// 基于 `lunar` 包的历法引擎实现。
class LunarCalendarEngine implements CalendarEngine {
  const LunarCalendarEngine();

  static const int _minSupportedYear = 1901;
  static const int _maxSupportedYear = 2099;

  @override
  Occurrence nextOccurrence(BirthdaySpec spec, DateTime from) {
    final today = _dateOnly(from);
    final candidate = spec.type == CalendarType.solar
        ? _nextSolar(spec, today)
        : _nextLunar(spec, today);
    final daysUntil = _civilDays(candidate) - _civilDays(today);
    final ageInYears =
        spec.birthYear == null ? null : candidate.year - spec.birthYear!;
    return Occurrence(
      date: candidate,
      daysUntil: daysUntil,
      isToday: daysUntil == 0,
      lunar: toLunar(candidate),
      ageInYears: ageInYears,
      xuSui: ageInYears == null ? null : ageInYears + 1,
    );
  }

  @override
  LunarInfo toLunar(DateTime date) {
    final lunar = Solar.fromYmd(date.year, date.month, date.day).getLunar();
    final month = lunar.getMonth();
    return LunarInfo(
      year: lunar.getYear(),
      month: month.abs(),
      day: lunar.getDay(),
      isLeapMonth: month < 0,
      monthInChinese: lunar.getMonthInChinese(),
      dayInChinese: lunar.getDayInChinese(),
    );
  }

  @override
  bool isValid(BirthdaySpec spec) {
    if (spec.month < 1 || spec.month > 12 || spec.day < 1) return false;

    if (spec.type == CalendarType.solar) {
      if (spec.day > 31) return false;
      // 用闰年做参照，允许 2 月 29 日的生日。
      return spec.day <= solarMonthDays(2000, spec.month);
    }

    if (spec.day > 30) return false;
    final birthYear = spec.birthYear;
    if (birthYear == null) return true;
    if (birthYear < _minSupportedYear || birthYear > _maxSupportedYear) {
      return false;
    }
    final days = lunarMonthDays(birthYear, spec.month, leapMonth: spec.leapMonth);
    if (days == 0) return false;
    return spec.day <= days;
  }

  @override
  String specLabel(BirthdaySpec spec) {
    if (spec.type == CalendarType.solar) {
      return '公历${spec.month}月${spec.day}日';
    }
    final monthName = LunarUtil.MONTH[_clamp(spec.month, 1, 12)];
    final dayName = LunarUtil.DAY[_clamp(spec.day, 1, 30)];
    return '农历${spec.leapMonth ? '闰' : ''}$monthName月$dayName';
  }

  @override
  DateTime? birthDate(BirthdaySpec spec) {
    final year = spec.birthYear;
    if (year == null) return null;
    if (spec.type == CalendarType.solar) {
      return _solarDate(year, spec.month, spec.day);
    }
    return _resolveLunar(year, spec);
  }

  @override
  int solarMonthDays(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  @override
  DateTime? birthdayInSolarYear(BirthdaySpec spec, int solarYear) {
    if (spec.type == CalendarType.solar) {
      return _solarDate(solarYear, spec.month, spec.day);
    }
    // 农历生日可能落在上一农历年（年末）或本年（年初之后）。
    for (var lunarYear = solarYear - 1; lunarYear <= solarYear; lunarYear++) {
      final date = _resolveLunar(lunarYear, spec);
      if (date != null && date.year == solarYear) return date;
    }
    return null;
  }

  @override
  int lunarMonthDays(int lunarYear, int month, {bool leapMonth = false}) {
    final year = LunarYear.fromYear(lunarYear);
    final target = leapMonth ? -month : month;
    final m = year.getMonth(target);
    return m?.getDayCount() ?? 0;
  }

  @override
  int leapMonthOf(int lunarYear) => LunarYear.fromYear(lunarYear).getLeapMonth();

  // ---------------------------------------------------------------------------

  DateTime _nextSolar(BirthdaySpec spec, DateTime from) {
    var candidate = _solarDate(from.year, spec.month, spec.day);
    if (_civilDays(candidate) < _civilDays(from)) {
      candidate = _solarDate(from.year + 1, spec.month, spec.day);
    }
    return candidate;
  }

  DateTime _solarDate(int year, int month, int day) {
    // 2 月 29 日在平年回退到 2 月 28 日。
    if (month == 2 && day == 29 && !_isLeapYear(year)) {
      return DateTime(year, 2, 28);
    }
    return DateTime(year, month, day);
  }

  DateTime _nextLunar(BirthdaySpec spec, DateTime from) {
    final fromLunarYear = Lunar.fromDate(from).getYear();
    for (var year = fromLunarYear; year <= fromLunarYear + 2; year++) {
      final candidate = _resolveLunar(year, spec);
      if (candidate != null &&
          _civilDays(candidate) >= _civilDays(from)) {
        return candidate;
      }
    }
    throw StateError('无法为 $spec 找到下一次农历生日');
  }

  /// 把 [spec] 在农历 [lunarYear] 年发生的日期解析为公历日期。
  ///
  /// 规则：
  /// - 生于闰月且该年存在对应闰月：按 [BirthdaySpec.preferLeap] 决定是否用闰月；
  /// - 生于闰月但该年无对应闰月：回退到同名平月；
  /// - 该月为小月（29 天）而生日为三十：回退到廿九。
  DateTime? _resolveLunar(int lunarYear, BirthdaySpec spec) {
    final year = LunarYear.fromYear(lunarYear);
    var targetMonth = spec.month;
    if (spec.leapMonth && year.getLeapMonth() == spec.month) {
      targetMonth = spec.preferLeap ? -spec.month : spec.month;
    }
    var month = year.getMonth(targetMonth);
    if (month == null) {
      targetMonth = spec.month;
      month = year.getMonth(targetMonth);
    }
    if (month == null) return null;

    final day = spec.day > month.getDayCount() ? month.getDayCount() : spec.day;
    final solar = Lunar.fromYmd(lunarYear, targetMonth, day).getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _civilDays(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int _clamp(int value, int min, int max) =>
      value < min ? min : (value > max ? max : value);
}
