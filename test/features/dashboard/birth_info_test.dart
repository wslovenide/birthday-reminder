import 'package:birth_remind/features/calendar/domain/birthday_spec.dart';
import 'package:birth_remind/features/calendar/domain/calendar_engine.dart';
import 'package:birth_remind/features/calendar/domain/calendar_type.dart';
import 'package:birth_remind/features/dashboard/domain/dashboard_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = LunarCalendarEngine();

  test('已知年份的农历生日显示年份与双历日期', () {
    final info = buildBirthInfo(
      const BirthdaySpec(
        type: CalendarType.lunar,
        month: 6,
        day: 1,
        birthYear: 2025,
      ),
      engine,
    );

    expect(info.year, '2025 年');
    expect(info.lunar, '农历2025年六月初一');
    expect(info.solar, '公历2025年6月25日');
  });

  test('已知年份的公历生日反推出农历', () {
    final info = buildBirthInfo(
      const BirthdaySpec(
        type: CalendarType.solar,
        month: 5,
        day: 5,
        birthYear: 2000,
      ),
      engine,
    );

    expect(info.year, '2000 年');
    expect(info.solar, '公历2000年5月5日');
    expect(info.lunar.startsWith('农历2000年'), isTrue);
    expect(info.lunar, isNot('填写出生年份后显示'));
  });

  test('腊月三十出生在无三十的年份回退，并正确跨公历年', () {
    final info = buildBirthInfo(
      const BirthdaySpec(
        type: CalendarType.lunar,
        month: 12,
        day: 30,
        birthYear: 2025,
      ),
      engine,
    );

    expect(info.lunar, '农历2025年腊月廿九');
    expect(info.solar, '公历2026年2月16日');
  });

  test('未填写出生年份的农历生日：显示规则并提示补全年份', () {
    final info = buildBirthInfo(
      const BirthdaySpec(type: CalendarType.lunar, month: 6, day: 1),
      engine,
    );

    expect(info.year, '未填写');
    expect(info.lunar, '农历六月初一');
    expect(info.solar, '填写出生年份后显示');
  });

  test('未填写出生年份的公历生日：显示规则并提示补全年份', () {
    final info = buildBirthInfo(
      const BirthdaySpec(type: CalendarType.solar, month: 2, day: 29),
      engine,
    );

    expect(info.year, '未填写');
    expect(info.solar, '公历2月29日');
    expect(info.lunar, '填写出生年份后显示');
  });
}
