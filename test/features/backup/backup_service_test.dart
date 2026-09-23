import 'dart:io';

import 'package:birth_remind/features/backup/domain/backup_codec.dart';
import 'package:birth_remind/features/backup/domain/backup_format_exception.dart';
import 'package:birth_remind/features/backup/domain/backup_service.dart';
import 'package:birth_remind/features/calendar/domain/birthday_spec.dart';
import 'package:birth_remind/features/calendar/domain/calendar_type.dart';
import 'package:birth_remind/features/persons/data/app_database.dart';
import 'package:birth_remind/features/persons/data/drift_person_repository.dart';
import 'package:birth_remind/features/persons/domain/person.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftPersonRepository repository;
  late BackupService service;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repository = DriftPersonRepository(db);
    service = BackupService(repository: repository);
  });

  tearDown(() => db.close());

  Person person({
    String name = '张三',
    String relationship = '家人',
    CalendarType type = CalendarType.lunar,
    int month = 8,
    int day = 15,
    int? birthYear = 1990,
    Set<int> offsets = const {0, 1},
    bool enabled = true,
  }) {
    return Person(
      name: name,
      relationship: relationship,
      birthday: BirthdaySpec(
        type: type,
        month: month,
        day: day,
        birthYear: birthYear,
      ),
      reminderOffsets: offsets,
      reminderEnabled: enabled,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  group('编解码', () {
    test('导出后可完整解析回来', () {
      const codec = BackupCodec();
      final original = [
        person(name: 'A'),
        person(name: 'B', type: CalendarType.solar, month: 3, day: 9),
      ];
      final data = codec.decode(codec.encode(original, now: DateTime(2026, 2, 1)));

      expect(data.schemaVersion, 1);
      expect(data.persons.length, 2);
      expect(data.persons.first.name, 'A');
      expect(data.persons.first.birthday.type, CalendarType.lunar);
      expect(data.persons.first.birthday.month, 8);
      expect(data.persons.first.reminderOffsets, {0, 1});
      expect(data.persons.last.birthday.type, CalendarType.solar);
    });

    test('拒绝高于当前版本的备份', () {
      const codec = BackupCodec();
      expect(
        () => codec.decode(
          '{"schemaVersion":99,"persons":[]}',
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('拒绝非法 JSON 与缺失字段', () {
      const codec = BackupCodec();
      expect(
        () => codec.decode('oops'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => codec.decode('{"schemaVersion":1}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('跳过损坏的联系人条目', () {
      const codec = BackupCodec();
      final data = codec.decode(
        '{"schemaVersion":1,"persons":['
        '{"name":"好的","month":5,"day":5,"calendarType":"solar"},'
        '{"name":"","month":5,"day":5},'
        '{"name":"缺月","day":5},'
        '"不是对象"'
        ']}',
      );
      expect(data.persons.length, 1);
      expect(data.persons.single.name, '好的');
    });
  });

  group('导入', () {
    test('覆盖模式清空旧数据后写入备份', () async {
      await repository.add(person(name: '旧数据'));
      final json = await service.exportToJson();

      await repository.clear();
      await repository.add(person(name: '干扰项'));

      final result = await service.importFromJson(
        json,
        strategy: ImportStrategy.overwrite,
      );

      final all = await repository.getAll();
      expect(all.map((p) => p.name), ['旧数据']);
      expect(result.added, 1);
      expect(result.removed, 1);
    });

    test('合并模式跳过已存在的联系人', () async {
      await repository.add(person(name: '张三'));
      final json = await service.exportToJson();

      final result = await service.importFromJson(
        json,
        strategy: ImportStrategy.merge,
      );

      final all = await repository.getAll();
      expect(all.length, 1);
      expect(result.added, 0);
      expect(result.skipped, 1);
      expect(result.removed, 0);
    });

    test('合并模式新增不存在的联系人', () async {
      await repository.add(person(name: '甲'));
      final json = await _exportOf([person(name: '乙')], service);

      final result = await service.importFromJson(
        json,
        strategy: ImportStrategy.merge,
      );

      final names = (await repository.getAll()).map((p) => p.name).toSet();
      expect(names, {'甲', '乙'});
      expect(result.added, 1);
    });

    test('重复导入同一文件不会产生重复数据', () async {
      final json = await _exportOf([person(name: 'A'), person(name: 'B')], service);
      await service.importFromJson(json, strategy: ImportStrategy.merge);
      final result = await service.importFromJson(
        json,
        strategy: ImportStrategy.merge,
      );
      expect(result.added, 0);
      expect((await repository.getAll()).length, 2);
    });
  });

  group('文件往返', () {
    test('导出到文件再导入', () async {
      await repository.add(person(name: '文件测试'));
      final dir = await Directory.systemTemp.createTemp('birth_backup_test');
      final path = '${dir.path}${Platform.pathSeparator}backup.json';

      await service.exportToFile(path);
      expect(await File(path).exists(), isTrue);

      await repository.clear();
      final result = await service.importFromFile(
        path,
        strategy: ImportStrategy.overwrite,
      );

      expect(result.added, 1);
      expect((await repository.getAll()).single.name, '文件测试');
      await dir.delete(recursive: true);
    });

    test('导入不存在的文件抛出格式异常', () async {
      expect(
        () => service.importFromFile(
          'definitely/missing.json',
          strategy: ImportStrategy.overwrite,
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}

Future<String> _exportOf(List<Person> persons, BackupService service) async {
  final temp = AppDatabase.withExecutor(NativeDatabase.memory());
  final repo = DriftPersonRepository(temp);
  final tempService = BackupService(repository: repo);
  for (final person in persons) {
    await repo.add(person);
  }
  final json = await tempService.exportToJson();
  await temp.close();
  return json;
}
