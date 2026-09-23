import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/reminders/providers/reminder_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gateway = await createNotificationGateway();
  final container = ProviderContainer(
    overrides: [notificationGatewayProvider.overrideWith((ref) => gateway)],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BirthRemindApp(),
    ),
  );

  await _bootstrapReminders(container);
}

/// 启动时申请通知权限并重建全部提醒。
Future<void> _bootstrapReminders(ProviderContainer container) async {
  try {
    final controller = container.read(reminderControllerProvider);
    await controller.ensurePermission();
    await controller.reschedule();
  } catch (error) {
    debugPrint('提醒初始化失败：$error');
  }
}
