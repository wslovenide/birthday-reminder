import '../../calendar/domain/calendar_engine.dart';
import '../../persons/domain/person.dart';
import '../../settings/domain/app_settings.dart';
import 'reminder_plan.dart';

/// 纯函数式的提醒计划生成器。
///
/// 根据联系人、设置与历法引擎计算所有待安排的通知：每位启用提醒的联系人
/// 与其每个「提前天数」组合产生一条计划。已过触发时刻的计划会被丢弃。
class ReminderPlanner {
  const ReminderPlanner(this._engine);

  final CalendarEngine _engine;

  List<ReminderPlan> buildPlans({
    required List<Person> persons,
    required AppSettings settings,
    required DateTime now,
  }) {
    final plans = <ReminderPlan>[];
    for (final person in persons) {
      if (!person.reminderEnabled) continue;
      if (person.reminderOffsets.isEmpty) continue;

      final occurrence = _engine.nextOccurrence(person.birthday, now);
      final offsets = person.reminderOffsets.toList()..sort();
      for (final offset in offsets) {
        final scheduledAt = DateTime(
          occurrence.date.year,
          occurrence.date.month,
          occurrence.date.day,
          settings.reminderHour,
          settings.reminderMinute,
        ).subtract(Duration(days: offset));

        if (!scheduledAt.isAfter(now)) continue;

        plans.add(
          ReminderPlan(
            notificationId: plans.length,
            personId: person.id,
            personName: person.name,
            daysBefore: offset,
            birthday: occurrence.date,
            scheduledAt: scheduledAt,
            title: '生日提醒',
            body: _body(person.name, offset, occurrence.date),
          ),
        );
      }
    }
    return plans;
  }

  String _body(String name, int daysBefore, DateTime birthday) {
    final date = '${birthday.month}月${birthday.day}日';
    if (daysBefore == 0) return '$name 今天生日！';
    if (daysBefore == 1) return '$name 明天生日（$date）';
    return '$name 还有 $daysBefore 天生日（$date）';
  }
}
