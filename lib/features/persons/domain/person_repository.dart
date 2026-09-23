import 'person.dart';

/// 联系人档案的读写接口。
abstract class PersonRepository {
  /// 读取全部联系人（按创建时间倒序）。
  Future<List<Person>> getAll();

  /// 实时监听全部联系人。
  Stream<List<Person>> watchAll();

  /// 按主键读取。
  Future<Person?> getById(int id);

  /// 新增联系人，返回新记录主键。
  Future<int> add(Person person);

  /// 更新联系人。
  Future<void> update(Person person);

  /// 删除联系人。
  Future<void> delete(int id);

  /// 清空全部联系人（用于导入覆盖）。
  Future<void> clear();

  /// 用给定集合替换全部联系人（保留其自增主键）。
  Future<void> replaceAll(List<Person> persons);
}
