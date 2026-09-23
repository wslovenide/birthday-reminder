import '../../persons/domain/person.dart';
import '../../settings/domain/app_settings.dart';
import 'notification_gateway.dart';
import 'reminder_plan.dart';
import 'reminder_planner.dart';

/// 提醒调度器：先生成计划，再幂等地重建全部通知。
///
/// 每次调用都会先取消全部旧通知再重新安排，因此重复调用不会产生重复提醒，
/// 应用启动、数据变更或导入后调用即可保持提醒与数据一致。
class ReminderScheduler {
  ReminderScheduler({required this.planner, required this.gateway});

  final ReminderPlanner planner;
  final NotificationGateway gateway;

  /// 重新安排全部提醒，返回实际安排的计划数量。
  Future<int> rescheduleAll(
    List<Person> persons,
    AppSettings settings, {
    DateTime? now,
  }) async {
    final plans = planner.buildPlans(
      persons: persons,
      settings: settings,
      now: now ?? DateTime.now(),
    );
    await gateway.cancelAll();
    for (final plan in plans) {
      await gateway.schedule(plan);
    }
    return plans.length;
  }

  /// 取消全部提醒。
  Future<void> cancelAll() => gateway.cancelAll();

  /// 生成计划（不接触网关），便于展示「下一次提醒时间」。
  List<ReminderPlan> plan(
    List<Person> persons,
    AppSettings settings, {
    DateTime? now,
  }) {
    return planner.buildPlans(
      persons: persons,
      settings: settings,
      now: now ?? DateTime.now(),
    );
  }
}
