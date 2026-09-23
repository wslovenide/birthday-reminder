import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/reminders/providers/reminder_providers.dart';
import 'features/settings/domain/age_display.dart';
import 'routes/app_router.dart';

/// 应用根组件。
class BirthRemindApp extends ConsumerWidget {
  const BirthRemindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode =
        ref.watch(settingsProvider).value?.themeMode ??
        AppThemeMode.system;

    ref.listen(selectedPersonFromNotificationProvider, (previous, next) {
      final personId = next.value;
      if (personId != null && personId > 0) {
        router.push('/person/$personId');
      }
    });

    return MaterialApp.router(
      title: '生日提醒',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _toThemeMode(themeMode),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeMode _toThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
