import 'calendar_type.dart';

/// 一个生日规格：描述“某人的生日如何重复发生”。
///
/// 生日以「历法类型 + 月 + 日」表达，而非固定某一天，因此每年都会自动
/// 重新计算对应的公历日期。农历生日额外区分是否生于闰月，以及闰月是否
/// 优先在闰月庆祝。
class BirthdaySpec {
  const BirthdaySpec({
    required this.type,
    required this.month,
    required this.day,
    this.leapMonth = false,
    this.preferLeap = false,
    this.birthYear,
  });

  /// 历法类型。
  final CalendarType type;

  /// 月份，1-12。
  final int month;

  /// 日期。公历 1-31，农历 1-30。
  final int day;

  /// 生日是否落在闰月（仅农历有意义）。
  final bool leapMonth;

  /// 当该农历年存在对应闰月时，是否优先在闰月庆祝（仅农历有意义）。
  final bool preferLeap;

  /// 出生年份，可为空（不知道年份时只提醒、不显示年龄）。
  final int? birthYear;

  BirthdaySpec copyWith({
    CalendarType? type,
    int? month,
    int? day,
    bool? leapMonth,
    bool? preferLeap,
    int? birthYear,
    bool clearBirthYear = false,
  }) {
    return BirthdaySpec(
      type: type ?? this.type,
      month: month ?? this.month,
      day: day ?? this.day,
      leapMonth: leapMonth ?? this.leapMonth,
      preferLeap: preferLeap ?? this.preferLeap,
      birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BirthdaySpec &&
      other.type == type &&
      other.month == month &&
      other.day == day &&
      other.leapMonth == leapMonth &&
      other.preferLeap == preferLeap &&
      other.birthYear == birthYear;

  @override
  int get hashCode =>
      Object.hash(type, month, day, leapMonth, preferLeap, birthYear);

  @override
  String toString() =>
      'BirthdaySpec(${type.name}, $month/$day, leap=$leapMonth, '
      'preferLeap=$preferLeap, birthYear=$birthYear)';
}
