import 'package:drift/drift.dart';

import '../domain/person.dart';
import '../domain/person_repository.dart';
import 'app_database.dart';
import 'person_mapper.dart';

/// 基于 drift 的 [PersonRepository] 实现。
class DriftPersonRepository implements PersonRepository {
  DriftPersonRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Person>> getAll() async {
    final rows = await (_db.select(_db.persons)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Stream<List<Person>> watchAll() {
    return (_db.select(_db.persons)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  @override
  Future<Person?> getById(int id) async {
    final row = await (_db.select(_db.persons)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<int> add(Person person) {
    return _db.into(_db.persons).insert(personToCompanion(person));
  }

  @override
  Future<void> update(Person person) async {
    await (_db.update(_db.persons)..where((t) => t.id.equals(person.id)))
        .write(personToCompanion(person));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.persons)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> clear() async {
    await _db.delete(_db.persons).go();
  }

  @override
  Future<void> replaceAll(List<Person> persons) async {
    await _db.transaction(() async {
      await clear();
      for (final person in persons) {
        await _db.into(_db.persons).insert(personToCompanion(person));
      }
    });
  }
}
