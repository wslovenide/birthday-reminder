import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persons/providers/person_providers.dart';
import '../../reminders/providers/reminder_providers.dart';
import '../domain/backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(repository: ref.watch(personRepositoryProvider));
});

/// 备份与恢复的编排入口，导入后自动重排提醒。
class BackupController {
  BackupController(this._ref);

  final Ref _ref;

  Future<String> exportToJson() =>
      _ref.read(backupServiceProvider).exportToJson();

  Future<void> exportToFile(String path) async {
    await _ref.read(backupServiceProvider).exportToFile(path);
  }

  Future<ImportResult> importFromFile(
    String path, {
    required ImportStrategy strategy,
  }) async {
    final result = await _ref
        .read(backupServiceProvider)
        .importFromFile(path, strategy: strategy);
    await _ref.read(reminderControllerProvider).reschedule();
    return result;
  }
}

final backupControllerProvider = Provider<BackupController>((ref) {
  return BackupController(ref);
});
