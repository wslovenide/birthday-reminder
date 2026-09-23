import 'dart:io';

import '../../persons/domain/person.dart';
import '../../persons/domain/person_repository.dart';
import 'backup_codec.dart';
import 'backup_format_exception.dart';
import 'backup_payload.dart';

/// 导入策略。
enum ImportStrategy {
  /// 合并：跳过已存在的联系人，仅新增。
  merge,

  /// 覆盖：清空现有数据后写入备份内容。
  overwrite,
}

/// 导入结果统计。
class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.removed,
    required this.strategy,
  });

  /// 新增数量。
  final int added;

  /// 因重复而跳过的数量。
  final int skipped;

  /// 覆盖模式下被清除的原有数量。
  final int removed;

  final ImportStrategy strategy;
}

/// 备份服务：导出联系人到 JSON，或从 JSON 导入。
class BackupService {
  BackupService({required this.repository, BackupCodec? codec})
    : codec = codec ?? const BackupCodec();

  final PersonRepository repository;
  final BackupCodec codec;

  /// 导出全部联系人为 JSON 字符串。
  Future<String> exportToJson({DateTime? now}) async {
    final persons = await repository.getAll();
    return codec.encode(persons, now: now);
  }

  /// 导出到文件。
  Future<File> exportToFile(String path, {DateTime? now}) async {
    final json = await exportToJson(now: now);
    final file = File(path);
    await file.writeAsString(json);
    return file;
  }

  /// 解析备份内容（不写库）。
  BackupData parse(String raw) => codec.decode(raw);

  /// 从 JSON 字符串导入。
  ///
  /// 顶层格式非法时抛出 [BackupFormatException]。
  Future<ImportResult> importFromJson(
    String raw, {
    required ImportStrategy strategy,
  }) async {
    final data = codec.decode(raw);
    final existing = await repository.getAll();
    final existingKeys = existing.map(_personKey).toSet();

    final seen = <String>{};
    final toAdd = <Person>[];
    for (final person in data.persons) {
      final key = _personKey(person);
      if (seen.contains(key)) continue;
      if (strategy == ImportStrategy.merge && existingKeys.contains(key)) {
        continue;
      }
      seen.add(key);
      toAdd.add(person);
    }

    if (strategy == ImportStrategy.overwrite) {
      await repository.clear();
    }
    for (final person in toAdd) {
      await repository.add(person);
    }

    return ImportResult(
      added: toAdd.length,
      skipped: data.persons.length - toAdd.length,
      removed: strategy == ImportStrategy.overwrite ? existing.length : 0,
      strategy: strategy,
    );
  }

  /// 从文件导入。
  Future<ImportResult> importFromFile(
    String path, {
    required ImportStrategy strategy,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw BackupFormatException('文件不存在：$path');
    }
    return importFromJson(await file.readAsString(), strategy: strategy);
  }

  static String _personKey(Person person) {
    final b = person.birthday;
    return [
      person.name,
      person.relationship,
      b.type.name,
      b.month,
      b.day,
      b.leapMonth,
      b.birthYear ?? '',
    ].join('|');
  }
}
