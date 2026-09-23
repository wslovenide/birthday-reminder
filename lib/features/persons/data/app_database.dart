import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../calendar/domain/calendar_type.dart';

part 'app_database.g.dart';

/// 联系人表。
@DataClassName('PersonRow')
class Persons extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get relationship => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get calendarType => textEnum<CalendarType>()();
  IntColumn get month => integer()();
  IntColumn get day => integer()();
  BoolColumn get leapMonth => boolean().withDefault(const Constant(false))();
  BoolColumn get preferLeap => boolean().withDefault(const Constant(false))();
  IntColumn get birthYear => integer().nullable()();
  TextColumn get reminderOffsets =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 键值设置表。
@DataClassName('SettingRow')
class SettingEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Persons, SettingEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'birth_remind'));

  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;
}
