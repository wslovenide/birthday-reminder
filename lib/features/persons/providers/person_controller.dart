import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../reminders/providers/reminder_providers.dart';
import '../domain/person.dart';
import 'person_providers.dart';

/// 联系人的增删改，并在变更后自动触发提醒重排。
class PersonController {
  PersonController(this._ref);

  final Ref _ref;

  /// 新增或更新联系人，返回其主键。
  Future<int> save(Person person) async {
    final repository = _ref.read(personRepositoryProvider);
    final now = DateTime.now();
    final int id;
    if (person.isPersisted) {
      await repository.update(person.copyWith(updatedAt: now));
      id = person.id;
    } else {
      id = await repository.add(person.copyWith(updatedAt: now));
    }
    await _ref.read(reminderControllerProvider).reschedule();
    return id;
  }

  Future<void> delete(int id) async {
    await _ref.read(personRepositoryProvider).delete(id);
    await _ref.read(reminderControllerProvider).reschedule();
  }

  Future<void> setReminderEnabled(Person person, bool enabled) async {
    await _ref.read(personRepositoryProvider).update(
      person.copyWith(reminderEnabled: enabled, updatedAt: DateTime.now()),
    );
    await _ref.read(reminderControllerProvider).reschedule();
  }
}

final personControllerProvider = Provider<PersonController>((ref) {
  return PersonController(ref);
});
