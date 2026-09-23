/// 一条待安排的本地通知计划。
class ReminderPlan {
  const ReminderPlan({
    required this.notificationId,
    required this.personId,
    required this.personName,
    required this.daysBefore,
    required this.birthday,
    required this.scheduledAt,
    required this.title,
    required this.body,
  });

  /// 通知 id（每次重排按顺序分配，0 起）。
  final int notificationId;

  final int personId;
  final String personName;

  /// 提前天数，0 表示生日当天。
  final int daysBefore;

  /// 生日当天的公历日期。
  final DateTime birthday;

  /// 通知触发的本地时间。
  final DateTime scheduledAt;

  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is ReminderPlan &&
      other.notificationId == notificationId &&
      other.personId == personId &&
      other.personName == personName &&
      other.daysBefore == daysBefore &&
      other.birthday == birthday &&
      other.scheduledAt == scheduledAt &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(
    notificationId,
    personId,
    personName,
    daysBefore,
    birthday,
    scheduledAt,
    title,
    body,
  );

  @override
  String toString() =>
      'ReminderPlan(#$notificationId, $personName, -$daysBefore d, '
      'at $scheduledAt)';
}
