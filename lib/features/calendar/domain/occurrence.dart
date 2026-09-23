import 'lunar_info.dart';

/// 一次生日发生（下一次生日）的计算结果。
class Occurrence {
  const Occurrence({
    required this.date,
    required this.daysUntil,
    required this.isToday,
    required this.lunar,
    this.ageInYears,
    this.xuSui,
  });

  /// 生日当天的公历日期（无时间部分）。
  final DateTime date;

  /// 距离生日还有多少天，0 表示今天。
  final int daysUntil;

  /// 是否就是今天。
  final bool isToday;

  /// 生日当天的农历信息。
  final LunarInfo lunar;

  /// 周岁（仅在知道出生年份时有值）。
  final int? ageInYears;

  /// 虚岁（仅在知道出生年份时有值）。
  final int? xuSui;

  @override
  String toString() =>
      'Occurrence($date, daysUntil=$daysUntil, isToday=$isToday, '
      'age=$ageInYears, xuSui=$xuSui)';
}
