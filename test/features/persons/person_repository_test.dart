import 'package:birth_remind/features/calendar/domain/birthday_spec.dart';
import 'package:birth_remind/features/calendar/domain/calendar_type.dart';
import 'package:birth_remind/features/persons/data/app_database.dart';
import 'package:birth_remind/features/persons/data/drift_person_repository.dart';
import 'package:birth_remind/features/persons/data/person_mapper.dart';
import 'package:birth_remind/features/persons/domain/person.dart';
import 'package:birth_remind/features/persons/domain/person_query.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftPersonRepository repository;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repository = DriftPersonRepository(db);
  });

  tearDown(() => db.close());

  Person person({
    String name = '张三',
    String relationship = '朋友',
    CalendarType type = CalendarType.solar,
    int month = 5,
    int day = 5,
    bool leapMonth = false,
    bool preferLeap = false,
    int? birthYear,
    Set<int> offsets = const {1, 3},
    bool reminderEnabled = true,
  }) {
    final now = DateTime(2026, 1, 1, 9, 30);
    return Person(
      name: name,
      relationship: relationship,
      birthday: BirthdaySpec(
        type: type,
        month: month,
        day: day,
        leapMonth: leapMonth,
        preferLeap: preferLeap,
        birthYear: birthYear,
      ),
      reminderOffsets: offsets,
      reminderEnabled: reminderEnabled,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('增删改查', () {
    test('新增后可以按主键读回，且字段完整', () async {
      final id = await repository.add(
        person(
          name: '李四',
          relationship: '家人',
          type: CalendarType.lunar,
          month: 8,
          day: 15,
          birthYear: 1990,
          offsets: {1, 7, 15},
        ),
      );

      final loaded = await repository.getById(id);
      expect(loaded, isNotNull);
      expect(loaded!.name, '李四');
      expect(loaded.relationship, '家人');
      expect(loaded.birthday.type, CalendarType.lunar);
      expect(loaded.birthday.month, 8);
      expect(loaded.birthday.day, 15);
      expect(loaded.birthday.birthYear, 1990);
      expect(loaded.reminderOffsets, {1, 7, 15});
      expect(loaded.reminderEnabled, isTrue);
    });

    test('getAll 按创建时间倒序返回', () async {
      final early = Person(
        name: '早',
        birthday: const BirthdaySpec(
          type: CalendarType.solar,
          month: 1,
          day: 1,
        ),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      final late = Person(
        name: '晚',
        birthday: const BirthdaySpec(
          type: CalendarType.solar,
          month: 2,
          day: 2,
        ),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await repository.add(early);
      await repository.add(late);

      final all = await repository.getAll();
      expect(all.map((p) => p.name), ['晚', '早']);
    });

    test('更新会覆盖字段', () async {
      final id = await repository.add(person(name: '旧名'));
      final loaded = (await repository.getById(id))!;
      final updated = loaded.copyWith(
        name: '新名',
        note: '喜欢喝茶',
        reminderEnabled: false,
      );

      await repository.update(updated);

      final again = (await repository.getById(id))!;
      expect(again.name, '新名');
      expect(again.note, '喜欢喝茶');
      expect(again.reminderEnabled, isFalse);
    });

    test('删除后查不到', () async {
      final id = await repository.add(person());
      await repository.delete(id);
      expect(await repository.getById(id), isNull);
      expect(await repository.getAll(), isEmpty);
    });

    test('replaceAll 覆盖全部记录', () async {
      await repository.add(person(name: '旧'));
      await repository.replaceAll([person(name: 'A'), person(name: 'B')]);

      final all = await repository.getAll();
      expect(all.map((p) => p.name).toSet(), {'A', 'B'});
    });

    test('watchAll 在新增后推送新数据', () async {
      final stream = repository.watchAll();
      final firstEmission = await stream.first;
      expect(firstEmission, isEmpty);

      await repository.add(person(name: '新来的'));
      final latest = await stream.firstWhere((list) => list.isNotEmpty);
      expect(latest.single.name, '新来的');
    });
  });

  group('提醒天数的序列化', () {
    test('编码后再解码保持一致（含排序）', () {
      const offsets = {15, 1, 7};
      final encoded = encodeReminderOffsets(offsets);
      expect(encoded, '[1,7,15]');
      expect(decodeReminderOffsets(encoded), offsets);
    });

    test('空集合编码为 []', () {
      expect(encodeReminderOffsets(const {}), '[]');
      expect(decodeReminderOffsets('[]'), isEmpty);
    });

    test('损坏数据回退为空集合', () {
      expect(decodeReminderOffsets('not-json'), isEmpty);
      expect(decodeReminderOffsets('{"a":1}'), isEmpty);
    });
  });

  group('搜索与筛选（纯函数）', () {
    List<Person> sample() => [
      person(name: '张三', relationship: '家人'),
      person(name: 'zhang 四', relationship: '朋友'),
      person(name: '李五', relationship: '家人'),
    ];

    test('按姓名子串搜索且忽略大小写', () {
      expect(
        filterPersons(sample(), query: 'ZHANG').map((p) => p.name),
        ['zhang 四'],
      );
    });

    test('按关系筛选', () {
      final family = filterPersons(sample(), relationship: '家人');
      expect(family.map((p) => p.name), ['张三', '李五']);
    });

    test('搜索与筛选可叠加', () {
      final result = filterPersons(
        sample(),
        query: '李',
        relationship: '家人',
      );
      expect(result.map((p) => p.name), ['李五']);
    });

    test('空查询返回全部', () {
      expect(filterPersons(sample()).length, 3);
    });
  });
}
