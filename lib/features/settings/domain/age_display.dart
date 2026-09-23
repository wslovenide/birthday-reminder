/// 年龄的显示方式。
enum AgeDisplay {
  /// 不显示年龄。
  none,

  /// 显示周岁。
  actual,

  /// 显示虚岁。
  xuSui,
}

/// App 主题模式（不依赖 Flutter，便于测试）。
enum AppThemeMode { system, light, dark }
