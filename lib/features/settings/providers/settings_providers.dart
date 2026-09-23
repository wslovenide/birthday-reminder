import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persons/providers/person_providers.dart';
import '../../reminders/providers/reminder_providers.dart';
import '../domain/app_settings.dart';

/// 设置的保存入口，保存后自动重排提醒。
class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  Future<void> save(AppSettings settings) async {
    await _ref.read(settingsRepositoryProvider).save(settings);
    await _ref.read(reminderControllerProvider).reschedule();
  }
}

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});
