import 'dart:convert';

import 'package:drift/drift.dart';

import '../../calendar/domain/birthday_spec.dart';
import '../domain/person.dart';
import 'app_database.dart';

/// 把数据库行映射为领域实体。
extension PersonRowMapper on PersonRow {
  Person toDomain() => Person(
    id: id,
    name: name,
    relationship: relationship,
    note: note,
    avatarPath: avatarPath,
    birthday: BirthdaySpec(
      type: calendarType,
      month: month,
      day: day,
      leapMonth: leapMonth,
      preferLeap: preferLeap,
      birthYear: birthYear,
    ),
    reminderOffsets: decodeReminderOffsets(reminderOffsets),
    reminderEnabled: reminderEnabled,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// 把领域实体映射为数据库写入对象。[withId] 为真时附带主键（用于更新）。
PersonsCompanion personToCompanion(Person person, {bool withId = false}) {
  return PersonsCompanion(
    id: withId ? Value(person.id) : const Value.absent(),
    name: Value(person.name),
    relationship: Value(person.relationship),
    note: Value(person.note),
    avatarPath: Value(person.avatarPath),
    calendarType: Value(person.birthday.type),
    month: Value(person.birthday.month),
    day: Value(person.birthday.day),
    leapMonth: Value(person.birthday.leapMonth),
    preferLeap: Value(person.birthday.preferLeap),
    birthYear: Value(person.birthday.birthYear),
    reminderOffsets: Value(encodeReminderOffsets(person.reminderOffsets)),
    reminderEnabled: Value(person.reminderEnabled),
    createdAt: Value(person.createdAt),
    updatedAt: Value(person.updatedAt),
  );
}

Set<int> decodeReminderOffsets(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<num>().map((e) => e.toInt()).toSet();
    }
  } on FormatException {
    // 忽略损坏的数据。
  }
  return <int>{};
}

String encodeReminderOffsets(Set<int> offsets) {
  final sorted = offsets.toList()..sort();
  return jsonEncode(sorted);
}
