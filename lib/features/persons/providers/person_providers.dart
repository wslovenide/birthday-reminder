import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/domain/calendar_engine.dart';
import '../../settings/data/drift_settings_repository.dart';
import '../../settings/domain/settings_repository.dart';
import '../data/app_database.dart';
import '../data/drift_person_repository.dart';
import '../domain/person.dart';
import '../domain/person_repository.dart';

/// 应用数据库（单例，随 provider 释放关闭）。
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return DriftPersonRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(databaseProvider));
});

final calendarEngineProvider = Provider<CalendarEngine>((ref) {
  return const LunarCalendarEngine();
});

/// 全部联系人的实时列表。
final personsProvider = StreamProvider<List<Person>>((ref) {
  return ref.watch(personRepositoryProvider).watchAll();
});

/// 单个联系人（用于详情页）；依赖列表流，数据变更后自动刷新。
final personByIdProvider = FutureProvider.family<Person?, int>((ref, id) {
  ref.watch(personsProvider);
  return ref.watch(personRepositoryProvider).getById(id);
});
