/// 某个公历日期对应的农历信息。
class LunarInfo {
  const LunarInfo({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.monthInChinese,
    required this.dayInChinese,
  });

  /// 农历年。
  final int year;

  /// 农历月（正整数，闰月由 [isLeapMonth] 表示）。
  final int month;

  /// 农历日。
  final int day;

  /// 是否为闰月。
  final bool isLeapMonth;

  /// 月份的汉字，如「正」「冬」「腊」；闰月时为「闰六」。
  final String monthInChinese;

  /// 日期的汉字，如「初一」「廿三」。
  final String dayInChinese;

  /// 例：农历闰六月初一。[monthInChinese] 已含「闰」前缀。
  String get label => '农历$monthInChinese月$dayInChinese';

  @override
  bool operator ==(Object other) =>
      other is LunarInfo &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.isLeapMonth == isLeapMonth;

  @override
  int get hashCode => Object.hash(year, month, day, isLeapMonth);

  @override
  String toString() => '$year-${isLeapMonth ? '-' : ''}$month-$day';
}
