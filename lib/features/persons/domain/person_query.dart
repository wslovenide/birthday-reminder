import 'person.dart';

/// 对联系人列表做搜索与关系筛选的纯函数。
///
/// [query] 按姓名做大小写不敏感的子串匹配；[relationship] 精确匹配关系。
List<Person> filterPersons(
  List<Person> persons, {
  String query = '',
  String? relationship,
}) {
  final trimmed = query.trim().toLowerCase();
  return persons.where((person) {
    if (relationship != null &&
        relationship.isNotEmpty &&
        person.relationship != relationship) {
      return false;
    }
    if (trimmed.isEmpty) return true;
    return person.name.toLowerCase().contains(trimmed);
  }).toList();
}
