import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persons/domain/person.dart';
import '../../persons/providers/person_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../data/flutter_notification_gateway.dart';
import '../domain/notification_gateway.dart';
import '../domain/reminder_plan.dart';
import '../domain/reminder_planner.dart';
import '../domain/reminder_scheduler.dart';

/// 通知网关；在 `main` 中以真实实现覆盖，测试中以假实现覆盖。
final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  throw UnimplementedError('notificationGatewayProvider 必须在 ProviderScope 中被覆盖');
});

final reminderPlannerProvider = Provider<ReminderPlanner>((ref) {
  return ReminderPlanner(ref.watch(calendarEngineProvider));
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler(
    planner: ref.watch(reminderPlannerProvider),
    gateway: ref.watch(notificationGatewayProvider),
  );
});

/// 设置流。
final settingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// 提醒的编排入口：读取最新数据并重排通知。
class ReminderController {
  ReminderController(this._ref);

  final Ref _ref;

  Future<int> reschedule() async {
    final persons = await _ref.read(personRepositoryProvider).getAll();
    final settings = await _ref
        .read(settingsRepositoryProvider)
        .load();
    return _ref.read(reminderSchedulerProvider).rescheduleAll(persons, settings);
  }

  Future<void> cancelAll() => _ref.read(reminderSchedulerProvider).cancelAll();

  /// 读取通知权限，未授予时请求。
  Future<bool> ensurePermission() async {
    return _ref.read(notificationGatewayProvider).requestPermission();
  }
}

final reminderControllerProvider = Provider<ReminderController>((ref) {
  return ReminderController(ref);
});

/// 点击通知后选中的联系人 id 流。
final selectedPersonFromNotificationProvider = StreamProvider<int>((ref) {
  return ref.watch(notificationGatewayProvider).selectedPersonIds;
});

/// 某位联系人未来已安排的提醒计划（用于详情页展示「下一次提醒」）。
final personReminderPlansProvider = Provider.family<List<ReminderPlan>, int>((
  ref,
  personId,
) {
  final persons = ref.watch(personsProvider).value ?? const <Person>[];
  final settings = ref.watch(settingsProvider).value;
  if (settings == null) return const <ReminderPlan>[];

  Person? person;
  for (final candidate in persons) {
    if (candidate.id == personId) {
      person = candidate;
      break;
    }
  }
  if (person == null) return const <ReminderPlan>[];
  return ref.watch(reminderSchedulerProvider).plan([person], settings);
});

/// 创建通知网关，失败时回退到空实现。
Future<NotificationGateway> createNotificationGateway() async {
  try {
    return await FlutterNotificationGateway.create();
  } catch (_) {
    return const NoopNotificationGateway();
  }
}

/// 不做任何事的通知网关，用于不支持通知的平台。
class NoopNotificationGateway implements NotificationGateway {
  const NoopNotificationGateway();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> schedule(ReminderPlan plan) async {}

  @override
  Stream<int> get selectedPersonIds => const Stream<int>.empty();
}
