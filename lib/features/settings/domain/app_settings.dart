import 'dart:convert';

import '../../calendar/domain/calendar_type.dart';
import 'age_display.dart';

/// 应用级设置。
class AppSettings {
  const AppSettings({
    this.defaultCalendarType = CalendarType.lunar,
    this.defaultReminderOffsets = const {0, 1},
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.ageDisplay = AgeDisplay.actual,
    this.themeMode = AppThemeMode.system,
  });

  /// 默认历法类型（新建联系人时预选）。
  final CalendarType defaultCalendarType;

  /// 默认提前提醒天数（0 表示当天）。
  final Set<int> defaultReminderOffsets;

  /// 提醒发送时刻（小时，0-23）。
  final int reminderHour;

  /// 提醒发送时刻（分钟，0-59）。
  final int reminderMinute;

  /// 年龄显示方式。
  final AgeDisplay ageDisplay;

  /// 主题模式。
  final AppThemeMode themeMode;

  static const AppSettings defaults = AppSettings();

  AppSettings copyWith({
    CalendarType? defaultCalendarType,
    Set<int>? defaultReminderOffsets,
    int? reminderHour,
    int? reminderMinute,
    AgeDisplay? ageDisplay,
    AppThemeMode? themeMode,
  }) {
    return AppSettings(
      defaultCalendarType: defaultCalendarType ?? this.defaultCalendarType,
      defaultReminderOffsets:
          defaultReminderOffsets ?? this.defaultReminderOffsets,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      ageDisplay: ageDisplay ?? this.ageDisplay,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'defaultCalendarType': defaultCalendarType.name,
    'defaultReminderOffsets': defaultReminderOffsets.toList()..sort(),
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'ageDisplay': ageDisplay.name,
    'themeMode': themeMode.name,
  };

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.defaultCalendarType == defaultCalendarType &&
      _sameSet(other.defaultReminderOffsets, defaultReminderOffsets) &&
      other.reminderHour == reminderHour &&
      other.reminderMinute == reminderMinute &&
      other.ageDisplay == ageDisplay &&
      other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(
    defaultCalendarType,
    Object.hashAllUnordered(defaultReminderOffsets),
    reminderHour,
    reminderMinute,
    ageDisplay,
    themeMode,
  );

  static bool _sameSet(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);
}

/// 把设置编码为 JSON 字符串。
String encodeAppSettings(AppSettings settings) =>
    jsonEncode(settings.toJson());

/// 从 JSON 字符串解码设置；字段缺失或非法时回退到默认值。
AppSettings decodeAppSettings(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return AppSettings.defaults;
  }
  if (decoded is! Map) return AppSettings.defaults;
  final map = decoded.cast<String, dynamic>();
  const defaults = AppSettings.defaults;
  return AppSettings(
    defaultCalendarType:
        _enumByName(CalendarType.values, map['defaultCalendarType']) ??
        defaults.defaultCalendarType,
    defaultReminderOffsets:
        _intSet(map['defaultReminderOffsets']) ?? defaults.defaultReminderOffsets,
    reminderHour:
        _intInRange(map['reminderHour'], 0, 23) ?? defaults.reminderHour,
    reminderMinute:
        _intInRange(map['reminderMinute'], 0, 59) ?? defaults.reminderMinute,
    ageDisplay:
        _enumByName(AgeDisplay.values, map['ageDisplay']) ?? defaults.ageDisplay,
    themeMode:
        _enumByName(AppThemeMode.values, map['themeMode']) ??
        defaults.themeMode,
  );
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is String) {
    for (final value in values) {
      if (value.name == name) return value;
    }
  }
  return null;
}

int? _intInRange(Object? value, int min, int max) {
  final parsed = value is int ? value : int.tryParse('$value');
  if (parsed == null || parsed < min || parsed > max) return null;
  return parsed;
}

Set<int>? _intSet(Object? value) {
  if (value is! List) return null;
  final result = <int>{};
  for (final item in value) {
    final parsed = item is int ? item : int.tryParse('$item');
    if (parsed != null && parsed >= 0 && parsed <= 365) {
      result.add(parsed);
    }
  }
  return result;
}
