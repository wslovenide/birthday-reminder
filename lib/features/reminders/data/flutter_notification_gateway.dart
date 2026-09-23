import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_gateway.dart';
import '../domain/reminder_plan.dart';

/// 基于 flutter_local_notifications 的 [NotificationGateway] 实现。
class FlutterNotificationGateway implements NotificationGateway {
  FlutterNotificationGateway._(this._plugin);

  static const String _channelId = 'birthday_reminders';
  static const String _channelName = '生日提醒';

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<int> _selected = StreamController<int>.broadcast();

  /// 创建并初始化网关。
  static Future<FlutterNotificationGateway> create() async {
    await _configureTimeZone();
    final plugin = FlutterLocalNotificationsPlugin();
    final gateway = FlutterNotificationGateway._(plugin);

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        final id = int.tryParse(payload);
        if (id != null) gateway._selected.add(id);
      },
    );
    return gateway;
  }

  static Future<void> _configureTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // 无法确定本地时区时保留 UTC，通知仍可安排。
    }
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return granted ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(ReminderPlan plan) async {
    await _plugin.zonedSchedule(
      id: plan.notificationId,
      title: plan.title,
      body: plan.body,
      scheduledDate: tz.TZDateTime.from(plan.scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: '亲友生日提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '${plan.personId}',
    );
  }

  @override
  Stream<int> get selectedPersonIds => _selected.stream;
}
