import '../../calendar/domain/birthday_spec.dart';
import '../../calendar/domain/calendar_engine.dart';
import '../../calendar/domain/calendar_type.dart';
import '../../calendar/domain/occurrence.dart';
import '../../persons/domain/person.dart';
import '../../settings/domain/age_display.dart';

/// 仪表盘上的一条记录：联系人 + 其下一次生日。
class DashboardEntry {
  const DashboardEntry({required this.person, required this.occurrence});

  final Person person;
  final Occurrence occurrence;
}

/// 按倒计时升序、同日按姓名排序（今日寿星自然置顶）。
List<DashboardEntry> sortDashboardEntries(List<DashboardEntry> entries) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final byDays = a.occurrence.daysUntil.compareTo(b.occurrence.daysUntil);
    if (byDays != 0) return byDays;
    return a.person.name.compareTo(b.person.name);
  });
  return sorted;
}

/// 倒计时文案：今天 / 明天 / 还有 N 天 / 已过 N 天。
String countdownLabel(int daysUntil) {
  if (daysUntil == 0) return '今天';
  if (daysUntil == 1) return '明天';
  if (daysUntil < 0) return '已过 ${-daysUntil} 天';
  return '还有 $daysUntil 天';
}

/// 生日日期文案：公历日期；农历生日额外附农历。
String birthdayDateLabel(Person person, Occurrence occurrence) {
  final solar = '${occurrence.date.month}月${occurrence.date.day}日';
  if (person.birthday.type == CalendarType.lunar) {
    return '$solar · ${occurrence.lunar.label}';
  }
  return solar;
}

/// 年龄文案，按设置返回周岁/虚岁或不显示。
String? ageLabel(Occurrence occurrence, AgeDisplay display) {
  switch (display) {
    case AgeDisplay.none:
      return null;
    case AgeDisplay.actual:
      final age = occurrence.ageInYears;
      return age == null ? null : '$age 岁';
    case AgeDisplay.xuSui:
      final xuSui = occurrence.xuSui;
      return xuSui == null ? null : '虚岁 $xuSui';
  }
}

/// 仪表盘统计概览。
class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.thisMonthCount,
    required this.passedThisYearCount,
    required this.upcomingThisYearCount,
  });

  final int total;
  final int thisMonthCount;
  final int passedThisYearCount;
  final int upcomingThisYearCount;
}

/// 详情页「生日信息」模块的展示文本。
class BirthInfoText {
  const BirthInfoText({
    required this.year,
    required this.lunar,
    required this.solar,
  });

  /// 出生年份，如「1990 年」或「未填写」。
  final String year;

  /// 农历日期。
  final String lunar;

  /// 公历日期。
  final String solar;
}

/// 由生日规格构造「出生年份 / 农历 / 公历」三段文本。
///
/// 已知出生年份时，农历与公历都给出含年份的完整日期（腊月出生会正确跨公历年）；
/// 未填写出生年份时只能显示固定的月日规则，另一侧提示需补全年份。
BirthInfoText buildBirthInfo(BirthdaySpec spec, CalendarEngine engine) {
  final year = spec.birthYear;
  final yearText = year == null ? '未填写' : '$year 年';

  final date = engine.birthDate(spec);
  if (date != null) {
    final lunar = engine.toLunar(date);
    return BirthInfoText(
      year: yearText,
      lunar: '农历${lunar.year}年${lunar.monthInChinese}月${lunar.dayInChinese}',
      solar: '公历${date.year}年${date.month}月${date.day}日',
    );
  }

  const needYear = '填写出生年份后显示';
  switch (spec.type) {
    case CalendarType.lunar:
      return BirthInfoText(
        year: yearText,
        lunar: engine.specLabel(spec),
        solar: needYear,
      );
    case CalendarType.solar:
      return BirthInfoText(
        year: yearText,
        lunar: needYear,
        solar: engine.specLabel(spec),
      );
  }
}
