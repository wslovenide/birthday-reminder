import '../../persons/domain/person.dart';

/// 备份文件的版本号。
const int backupSchemaVersion = 1;

/// 一次备份导出的内容。
class BackupData {
  const BackupData({
    required this.schemaVersion,
    required this.exportedAt,
    required this.persons,
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final List<Person> persons;
}
