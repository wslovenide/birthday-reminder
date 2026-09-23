import 'dart:async';

import 'package:birth_remind/features/calendar/domain/birthday_spec.dart';
import 'package:birth_remind/features/calendar/domain/calendar_engine.dart';
import 'package:birth_remind/features/calendar/domain/calendar_type.dart';
import 'package:birth_remind/features/persons/domain/person.dart';
import 'package:birth_remind/features/reminders/domain/notification_gateway.dart';
import 'package:birth_remind/features/reminders/domain/reminder_plan.dart';
import 'package:birth_remind/features/reminders/domain/reminder_planner.dart';
import 'package:birth_remind/features/reminders/domain/reminder_scheduler.dart';
import 'package:birth_remind/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificationGateway implements NotificationGateway {
  final List<ReminderPlan> scheduled = [];
  int cancelAllCount = 0;
  int scheduleCount = 0;
  bool permissionGranted = true;
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<void> schedule(ReminderPlan plan) async {
    scheduleCount++;
    scheduled.add(plan);
  }

  @override
  Stream<int> get selectedPersonIds => _controller.stream;

  Future<void> dispose() => _controller.close();
}

void main() {
  const engine = LunarCalendarEngine();
  const planner = ReminderPlanner(engine);
  final now = DateTime(2026, 5, 1, 8, 0);

  Person person({
    int id = 1,
    String name = '小明',
    CalendarType type = CalendarType.solar,
    int month = 6,
    int day = 1,
    Set<int> offsets = const {0, 1, 3},
    bool enabled = true,
  }) {
    return Person(
      id: id,
      name: name,
      birthday: BirthdaySpec(type: type, month: month, day: day),
      reminderOffsets: offsets,
      reminderEnabled: enabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('ReminderPlanner', () {
    test('每位联系人按其提前天数产生计划', () {
      final plans = planner.buildPlans(
        persons: [person()],
        settings: AppSettings.defaults,
        now: now,
      );
      expect(plans.length, 3);
      expect(plans[0].notificationId, 0);
      expect(plans[1].notificationId, 1);
      expect(plans[2].notificationId, 2);
      expect(plans.map((p) => p.daysBefore), [0, 1, 3]);
    });

    test('触发时间为生日当天减去提前天数，并采用设置中的时刻', () {
      final plans = planner.buildPlans(
        persons: [person()],
        settings: const AppSettings(reminderHour: 7, reminderMinute: 30),
        now: now,
      );
      final onDay = plans.firstWhere((p) => p.daysBefore == 0);
      expect(onDay.scheduledAt, DateTime(2026, 6, 1, 7, 30));

      final three = plans.firstWhere((p) => p.daysBefore == 3);
      expect(three.scheduledAt, DateTime(2026, 5, 29, 7, 30));
    });

    test('文案随提前天数变化', () {
      final plans = planner.buildPlans(
        persons: [person(name: '小明')],
        settings: AppSettings.defaults,
        now: now,
      );
      expect(
        plans.firstWhere((p) => p.daysBefore == 0).body,
        '小明 今天生日！',
      );
      expect(
        plans.firstWhere((p) => p.daysBefore == 1).body,
        '小明 明天生日（6月1日）',
      );
      expect(
        plans.firstWhere((p) => p.daysBefore == 3).body,
        '小明 还有 3 天生日（6月1日）',
      );
    });

    test('停用提醒的联系人不产生计划', () {
      final plans = planner.buildPlans(
        persons: [person(enabled: false)],
        settings: AppSettings.defaults,
        now: now,
      );
      expect(plans, isEmpty);
    });

    test('无提醒天数的联系人不产生计划', () {
      final plans = planner.buildPlans(
        persons: [person(offsets: const {})],
        settings: AppSettings.defaults,
        now: now,
      );
      expect(plans, isEmpty);
    });

    test('已过触发时刻的计划被丢弃', () {
      // 生日 5 月 2 日，5 月 1 日 10:00 时，「提前 1 天」应于 5 月 1 日 9:00 触发，已过。
      final plans = planner.buildPlans(
        persons: [
          person(month: 5, day: 2, offsets: const {0, 1}),
        ],
        settings: AppSettings.defaults,
        now: DateTime(2026, 5, 1, 10, 0),
      );
      expect(plans.map((p) => p.daysBefore), [0]);
    });

    test('农历生日按历法引擎换算后的日期安排提醒', () {
      final plans = planner.buildPlans(
        persons: [
          person(type: CalendarType.lunar, month: 5, day: 5, offsets: const {0}),
        ],
        settings: AppSettings.defaults,
        now: DateTime(2026, 1, 1),
      );
      expect(plans.single.birthday, DateTime(2026, 6, 19));
    });

    test('多位联系人各自产生计划', () {
      final plans = planner.buildPlans(
        persons: [
          person(id: 1, name: 'A', offsets: const {0}),
          person(id: 2, name: 'B', month: 7, day: 1, offsets: const {1}),
        ],
        settings: AppSettings.defaults,
        now: now,
      );
      expect(plans.length, 2);
      expect(plans.map((p) => p.personId), [1, 2]);
    });
  });

  group('ReminderScheduler', () {
    late FakeNotificationGateway gateway;
    late ReminderScheduler scheduler;

    setUp(() {
      gateway = FakeNotificationGateway();
      scheduler = ReminderScheduler(planner: planner, gateway: gateway);
    });

    tearDown(() => gateway.dispose());

    test('rescheduleAll 先取消旧通知再安排新通知', () async {
      final count = await scheduler.rescheduleAll(
        [person(offsets: const {0, 3})],
        AppSettings.defaults,
        now: now,
      );
      expect(count, 2);
      expect(gateway.cancelAllCount, 1);
      expect(gateway.scheduled.length, 2);
    });

    test('重复调用保持幂等，不积累重复通知', () async {
      final persons = [person(offsets: const {0, 3})];
      await scheduler.rescheduleAll(persons, AppSettings.defaults, now: now);
      await scheduler.rescheduleAll(persons, AppSettings.defaults, now: now);
      expect(gateway.cancelAllCount, 2);
      expect(gateway.scheduled.length, 2);
    });

    test('没有联系人时也会清空通知', () async {
      await scheduler.rescheduleAll([], AppSettings.defaults, now: now);
      expect(gateway.scheduled, isEmpty);
      expect(gateway.cancelAllCount, 1);
    });

    test('plan 不接触网关', () async {
      final plans = scheduler.plan(
        [person(offsets: const {0})],
        AppSettings.defaults,
        now: now,
      );
      expect(plans.length, 1);
      expect(gateway.scheduleCount, 0);
      expect(gateway.cancelAllCount, 0);
    });
  });
}
