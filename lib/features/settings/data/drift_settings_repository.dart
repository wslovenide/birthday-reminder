import 'package:drift/drift.dart';

import '../../persons/data/app_database.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

/// 基于 drift 键值表的 [SettingsRepository] 实现。
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  static const String _key = 'app_settings';

  final AppDatabase _db;

  @override
  Future<AppSettings> load() async {
    final row = await _rowQuery().getSingleOrNull();
    if (row == null) return AppSettings.defaults;
    return decodeAppSettings(row.value);
  }

  @override
  Stream<AppSettings> watch() {
    return _rowQuery().watchSingleOrNull().map(
      (row) => row == null ? AppSettings.defaults : decodeAppSettings(row.value),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _db
        .into(_db.settingEntries)
        .insertOnConflictUpdate(
          SettingEntriesCompanion.insert(
            key: _key,
            value: encodeAppSettings(settings),
          ),
        );
  }

  SimpleSelectStatement<$SettingEntriesTable, SettingRow> _rowQuery() =>
      _db.select(_db.settingEntries)..where((t) => t.key.equals(_key));
}
