import '../../calendar/domain/birthday_spec.dart';

/// 一位联系人及其生日、提醒配置。
class Person {
  const Person({
    this.id = 0,
    required this.name,
    this.relationship = '',
    this.note = '',
    this.avatarPath,
    required this.birthday,
    this.reminderOffsets = const {},
    this.reminderEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 数据库主键；未保存时为 0。
  final int id;
  final String name;
  final String relationship;
  final String note;
  final String? avatarPath;

  /// 生日规格（历法类型 + 月/日 + 闰月等）。
  final BirthdaySpec birthday;

  /// 提前提醒天数集合，如 {1, 3, 7}。
  final Set<int> reminderOffsets;

  /// 是否启用提醒。
  final bool reminderEnabled;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// 是否为已持久化的记录。
  bool get isPersisted => id != 0;

  Person copyWith({
    int? id,
    String? name,
    String? relationship,
    String? note,
    String? avatarPath,
    bool clearAvatar = false,
    BirthdaySpec? birthday,
    Set<int>? reminderOffsets,
    bool? reminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      note: note ?? this.note,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      birthday: birthday ?? this.birthday,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Person &&
      other.id == id &&
      other.name == name &&
      other.relationship == relationship &&
      other.note == note &&
      other.avatarPath == avatarPath &&
      other.birthday == birthday &&
      _sameOffsets(other.reminderOffsets, reminderOffsets) &&
      other.reminderEnabled == reminderEnabled;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    relationship,
    note,
    avatarPath,
    birthday,
    Object.hashAllUnordered(reminderOffsets),
    reminderEnabled,
  );

  static bool _sameOffsets(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  String toString() => 'Person(id=$id, name=$name, birthday=$birthday)';
}
