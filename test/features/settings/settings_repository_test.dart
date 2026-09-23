import 'package:birth_remind/features/calendar/domain/calendar_type.dart';
import 'package:birth_remind/features/persons/data/app_database.dart';
import 'package:birth_remind/features/settings/data/drift_settings_repository.dart';
import 'package:birth_remind/features/settings/domain/age_display.dart';
import 'package:birth_remind/features/settings/domain/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('序列化', () {
    test('完整往返一致', () {
      const settings = AppSettings(
        defaultCalendarType: CalendarType.solar,
        defaultReminderOffsets: {7, 1, 3},
        reminderHour: 20,
        reminderMinute: 30,
        ageDisplay: AgeDisplay.xuSui,
        themeMode: AppThemeMode.dark,
      );
      expect(decodeAppSettings(encodeAppSettings(settings)), settings);
    });

    test('损坏 JSON 回退默认值', () {
      expect(decodeAppSettings('not-json'), AppSettings.defaults);
      expect(decodeAppSettings('[]'), AppSettings.defaults);
    });

    test('非法字段各自回退默认值', () {
      final decoded = decodeAppSettings(
        '{"defaultCalendarType":"bogus","reminderHour":99,'
        '"defaultReminderOffsets":"x","ageDisplay":"nope"}',
      );
      expect(decoded.defaultCalendarType, AppSettings.defaults.defaultCalendarType);
      expect(decoded.reminderHour, AppSettings.defaults.reminderHour);
      expect(
        decoded.defaultReminderOffsets,
        AppSettings.defaults.defaultReminderOffsets,
      );
      expect(decoded.ageDisplay, AppSettings.defaults.ageDisplay);
    });

    test('部分字段缺失时保留默认其余项', () {
      final decoded = decodeAppSettings('{"reminderHour":7}');
      expect(decoded.reminderHour, 7);
      expect(decoded.themeMode, AppSettings.defaults.themeMode);
    });
  });

  group('仓储', () {
    late AppDatabase db;
    late DriftSettingsRepository repository;

    setUp(() {
      db = AppDatabase.withExecutor(NativeDatabase.memory());
      repository = DriftSettingsRepository(db);
    });

    tearDown(() => db.close());

    test('未保存时读取默认值', () async {
      expect(await repository.load(), AppSettings.defaults);
    });

    test('保存后可读回', () async {
      const settings = AppSettings(
        defaultCalendarType: CalendarType.solar,
        defaultReminderOffsets: {1, 3},
        reminderHour: 18,
        reminderMinute: 45,
        ageDisplay: AgeDisplay.none,
        themeMode: AppThemeMode.light,
      );
      await repository.save(settings);
      expect(await repository.load(), settings);
    });

    test('save 多次是覆盖而非追加', () async {
      await repository.save(AppSettings.defaults);
      await repository.save(
        const AppSettings(reminderHour: 6, reminderMinute: 15),
      );
      final rows = await db.select(db.settingEntries).get();
      expect(rows.length, 1);
      expect((await repository.load()).reminderHour, 6);
    });

    test('watch 在保存后推送新值', () async {
      final stream = repository.watch();
      expect(await stream.first, AppSettings.defaults);

      await repository.save(const AppSettings(reminderHour: 22));
      final updated = await stream.firstWhere((s) => s.reminderHour == 22);
      expect(updated.reminderHour, 22);
    });
  });
}
