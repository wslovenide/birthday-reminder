/// 联系人关系的预设选项；用户也可填写自定义文字。
class Relationships {
  const Relationships._();

  static const String family = '家人';
  static const String friend = '朋友';
  static const String colleague = '同事';
  static const String other = '其他';

  static const List<String> presets = [family, friend, colleague, other];
}
