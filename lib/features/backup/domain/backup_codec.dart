import 'dart:convert';

import '../../calendar/domain/birthday_spec.dart';
import '../../calendar/domain/calendar_type.dart';
import '../../persons/domain/person.dart';
import 'backup_format_exception.dart';
import 'backup_payload.dart';

/// 备份数据的 JSON 编解码。
///
/// 顶层结构非法时抛出 [BackupFormatException]；单条联系人数据损坏时跳过该条，
/// 保证部分损坏的备份仍可恢复出其余数据。
class BackupCodec {
  const BackupCodec();

  String encode(List<Person> persons, {DateTime? now}) {
    final payload = {
      'schemaVersion': backupSchemaVersion,
      'exportedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'persons': persons.map(_personToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  BackupData decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupFormatException('文件不是合法的 JSON');
    }
    if (decoded is! Map) {
      throw const BackupFormatException('备份根节点必须是对象');
    }
    final map = decoded.cast<String, dynamic>();

    final version = map['schemaVersion'];
    if (version is! int) {
      throw const BackupFormatException('缺少 schemaVersion');
    }
    if (version > backupSchemaVersion) {
      throw BackupFormatException(
        '备份版本 $version 高于当前支持版本 $backupSchemaVersion',
      );
    }

    final rawPersons = map['persons'];
    if (rawPersons is! List) {
      throw const BackupFormatException('缺少 persons 列表');
    }

    final persons = <Person>[];
    for (final entry in rawPersons) {
      final person = _personFromJson(entry);
      if (person != null) persons.add(person);
    }

    return BackupData(
      schemaVersion: version,
      exportedAt: _parseDate(map['exportedAt']) ?? DateTime.now(),
      persons: persons,
    );
  }

  Map<String, dynamic> _personToJson(Person person) {
    final b = person.birthday;
    return {
      'name': person.name,
      'relationship': person.relationship,
      'note': person.note,
      'calendarType': b.type.name,
      'month': b.month,
      'day': b.day,
      'leapMonth': b.leapMonth,
      'preferLeap': b.preferLeap,
      'birthYear': b.birthYear,
      'reminderOffsets': person.reminderOffsets.toList()..sort(),
      'reminderEnabled': person.reminderEnabled,
      'createdAt': person.createdAt.toUtc().toIso8601String(),
    };
  }

  Person? _personFromJson(Object? entry) {
    if (entry is! Map) return null;
    final map = entry.cast<String, dynamic>();

    final name = map['name'];
    final month = _asInt(map['month']);
    final day = _asInt(map['day']);
    if (name is! String || name.trim().isEmpty) return null;
    if (month == null || day == null) return null;

    final type = _enumByName(CalendarType.values, map['calendarType']) ??
        CalendarType.solar;
    final birthYear = _asInt(map['birthYear']);
    final now = DateTime.now();

    return Person(
      name: name,
      relationship: map['relationship'] is String
          ? map['relationship'] as String
          : '',
      note: map['note'] is String ? map['note'] as String : '',
      birthday: BirthdaySpec(
        type: type,
        month: month,
        day: day,
        leapMonth: map['leapMonth'] == true,
        preferLeap: map['preferLeap'] == true,
        birthYear: birthYear,
      ),
      reminderOffsets: _intSet(map['reminderOffsets']) ?? const {0},
      reminderEnabled: map['reminderEnabled'] != false,
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: now,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Set<int>? _intSet(Object? value) {
    if (value is! List) return null;
    final result = <int>{};
    for (final item in value) {
      final parsed = _asInt(item);
      if (parsed != null && parsed >= 0 && parsed <= 365) result.add(parsed);
    }
    return result;
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is String) {
      for (final value in values) {
        if (value.name == name) return value;
      }
    }
    return null;
  }
}
