import 'package:birth_remind/features/calendar/domain/birthday_spec.dart';
import 'package:birth_remind/features/calendar/domain/calendar_engine.dart';
import 'package:birth_remind/features/calendar/domain/calendar_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = LunarCalendarEngine();

  DateTime d(int y, int m, int day) => DateTime(y, m, day);

  group('toLunar', () {
    test('春节：2026-02-17 为农历正月初一', () {
      final lunar = engine.toLunar(d(2026, 2, 17));
      expect(lunar.year, 2026);
      expect(lunar.month, 1);
      expect(lunar.day, 1);
      expect(lunar.isLeapMonth, isFalse);
      expect(lunar.monthInChinese, '正');
      expect(lunar.dayInChinese, '初一');
      expect(lunar.label, '农历正月初一');
    });

    test('2026-09-23 为农历八月十三', () {
      final lunar = engine.toLunar(d(2026, 9, 23));
      expect(lunar.year, 2026);
      expect(lunar.month, 8);
      expect(lunar.day, 13);
      expect(lunar.label, '农历八月十三');
    });

    test('2026-02-10 仍属农历乙巳年腊月廿三', () {
      final lunar = engine.toLunar(d(2026, 2, 10));
      expect(lunar.year, 2025);
      expect(lunar.month, 12);
      expect(lunar.day, 23);
    });

    test('闰月：2025-07-25 为农历闰六月初一', () {
      final lunar = engine.toLunar(d(2025, 7, 25));
      expect(lunar.year, 2025);
      expect(lunar.month, 6);
      expect(lunar.day, 1);
      expect(lunar.isLeapMonth, isTrue);
      expect(lunar.label, '农历闰六月初一');
    });
  });

  group('specLabel', () {
    test('公历', () {
      expect(
        engine.specLabel(
          const BirthdaySpec(type: CalendarType.solar, month: 5, day: 5),
        ),
        '公历5月5日',
      );
    });

    test('农历', () {
      expect(
        engine.specLabel(
          const BirthdaySpec(type: CalendarType.lunar, month: 5, day: 5),
        ),
        '农历五月初五',
      );
    });

    test('农历闰月', () {
      expect(
        engine.specLabel(
          const BirthdaySpec(
            type: CalendarType.lunar,
            month: 6,
            day: 1,
            leapMonth: true,
          ),
        ),
        '农历闰六月初一',
      );
    });
  });

  group('nextOccurrence - 公历', () {
    const spec = BirthdaySpec(type: CalendarType.solar, month: 5, day: 5);

    test('未来生日返回今年日期并给出倒计时', () {
      final occ = engine.nextOccurrence(spec, d(2026, 1, 1));
      expect(occ.date, d(2026, 5, 5));
      expect(occ.daysUntil, 124);
      expect(occ.isToday, isFalse);
    });

    test('生日当天 daysUntil 为 0 且 isToday 为真', () {
      final occ = engine.nextOccurrence(spec, d(2026, 5, 5));
      expect(occ.daysUntil, 0);
      expect(occ.isToday, isTrue);
    });

    test('生日已过则滚动到下一年', () {
      final occ = engine.nextOccurrence(spec, d(2026, 5, 6));
      expect(occ.date, d(2027, 5, 5));
    });

    test('2 月 29 日在平年回退到 2 月 28 日', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.solar, month: 2, day: 29),
        d(2026, 1, 1),
      );
      expect(occ.date, d(2026, 2, 28));
    });

    test('2 月 29 日在闰年正常', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.solar, month: 2, day: 29),
        d(2028, 1, 1),
      );
      expect(occ.date, d(2028, 2, 29));
    });

    test('12 月 31 日生日当天', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.solar, month: 12, day: 31),
        d(2026, 12, 31),
      );
      expect(occ.date, d(2026, 12, 31));
      expect(occ.daysUntil, 0);
    });
  });

  group('nextOccurrence - 农历', () {
    test('春节：2026-01-01 的下一次是 2026-02-17', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.lunar, month: 1, day: 1),
        d(2026, 1, 1),
      );
      expect(occ.date, d(2026, 2, 17));
      expect(occ.daysUntil, 47);
    });

    test('端午节：2026 年为 2026-06-19', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.lunar, month: 5, day: 5),
        d(2026, 1, 1),
      );
      expect(occ.date, d(2026, 6, 19));
    });

    test('中秋节当天为今天', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.lunar, month: 8, day: 15),
        d(2026, 9, 25),
      );
      expect(occ.date, d(2026, 9, 25));
      expect(occ.isToday, isTrue);
    });

    test('中秋节已过则滚动到 2027-09-15', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.lunar, month: 8, day: 15),
        d(2026, 9, 26),
      );
      expect(occ.date, d(2027, 9, 15));
    });

    test('闰月生日且优先闰月：2025 年取闰六月初一', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(
          type: CalendarType.lunar,
          month: 6,
          day: 1,
          leapMonth: true,
          preferLeap: true,
        ),
        d(2025, 1, 1),
      );
      expect(occ.date, d(2025, 7, 25));
      expect(occ.lunar.isLeapMonth, isTrue);
    });

    test('闰月生日但不优先闰月：2025 年取平六月初一', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(
          type: CalendarType.lunar,
          month: 6,
          day: 1,
          leapMonth: true,
          preferLeap: false,
        ),
        d(2025, 1, 1),
      );
      expect(occ.date, d(2025, 6, 25));
      expect(occ.lunar.isLeapMonth, isFalse);
    });

    test('闰月生日遇无对应闰月的年份回退到平月', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(
          type: CalendarType.lunar,
          month: 6,
          day: 1,
          leapMonth: true,
          preferLeap: true,
        ),
        d(2026, 1, 1),
      );
      expect(occ.date.year, 2026);
      expect(occ.lunar.month, 6);
      expect(occ.lunar.isLeapMonth, isFalse);
    });

    test('腊月三十在只有廿九的年份回退到腊月廿九', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.lunar, month: 12, day: 30),
        d(2025, 12, 1),
      );
      expect(occ.date, d(2026, 2, 16));
      expect(occ.lunar.label, '农历腊月廿九');
    });
  });

  group('年龄', () {
    test('公历生日计算周岁与虚岁', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(
          type: CalendarType.solar,
          month: 5,
          day: 5,
          birthYear: 2000,
        ),
        d(2026, 1, 1),
      );
      expect(occ.ageInYears, 26);
      expect(occ.xuSui, 27);
    });

    test('农历生日计算周岁与虚岁', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(
          type: CalendarType.lunar,
          month: 1,
          day: 1,
          birthYear: 2000,
        ),
        d(2026, 1, 1),
      );
      expect(occ.ageInYears, 26);
      expect(occ.xuSui, 27);
    });

    test('不知道出生年份时年龄为空', () {
      final occ = engine.nextOccurrence(
        const BirthdaySpec(type: CalendarType.solar, month: 5, day: 5),
        d(2026, 1, 1),
      );
      expect(occ.ageInYears, isNull);
      expect(occ.xuSui, isNull);
    });
  });

  group('isValid', () {
    test('公历合法与非法日期', () {
      expect(
        engine.isValid(
          const BirthdaySpec(type: CalendarType.solar, month: 2, day: 29),
        ),
        isTrue,
      );
      expect(
        engine.isValid(
          const BirthdaySpec(type: CalendarType.solar, month: 4, day: 31),
        ),
        isFalse,
      );
      expect(
        engine.isValid(
          const BirthdaySpec(type: CalendarType.solar, month: 13, day: 1),
        ),
        isFalse,
      );
    });

    test('农历无年份时只校验 1-30', () {
      expect(
        engine.isValid(
          const BirthdaySpec(type: CalendarType.lunar, month: 6, day: 30),
        ),
        isTrue,
      );
      expect(
        engine.isValid(
          const BirthdaySpec(type: CalendarType.lunar, month: 6, day: 31),
        ),
        isFalse,
      );
    });

    test('农历有大月 30 天时三十合法', () {
      expect(
        engine.isValid(
          const BirthdaySpec(
            type: CalendarType.lunar,
            month: 6,
            day: 30,
            birthYear: 2025,
          ),
        ),
        isTrue,
      );
    });

    test('农历小月没有三十则不合法', () {
      expect(
        engine.isValid(
          const BirthdaySpec(
            type: CalendarType.lunar,
            month: 5,
            day: 30,
            birthYear: 2025,
          ),
        ),
        isFalse,
      );
    });

    test('出生年份无对应闰月则不合法', () {
      expect(
        engine.isValid(
          const BirthdaySpec(
            type: CalendarType.lunar,
            month: 6,
            day: 1,
            leapMonth: true,
            birthYear: 2026,
          ),
        ),
        isFalse,
      );
    });
  });

  group('birthdayInSolarYear', () {
    test('公历生日返回当年日期', () {
      expect(
        engine.birthdayInSolarYear(
          const BirthdaySpec(type: CalendarType.solar, month: 5, day: 5),
          2026,
        ),
        d(2026, 5, 5),
      );
    });

    test('公历 2 月 29 日在平年回退', () {
      expect(
        engine.birthdayInSolarYear(
          const BirthdaySpec(type: CalendarType.solar, month: 2, day: 29),
          2026,
        ),
        d(2026, 2, 28),
      );
    });

    test('农历生日返回当年对应公历日期', () {
      expect(
        engine.birthdayInSolarYear(
          const BirthdaySpec(type: CalendarType.lunar, month: 8, day: 15),
          2026,
        ),
        d(2026, 9, 25),
      );
    });

    test('年末农历生日跨公历年时归入正确年份', () {
      expect(
        engine.birthdayInSolarYear(
          const BirthdaySpec(type: CalendarType.lunar, month: 12, day: 30),
          2026,
        ),
        d(2026, 2, 16),
      );
    });
  });

  group('历法查询', () {
    test('公历每月天数', () {
      expect(engine.solarMonthDays(2024, 2), 29);
      expect(engine.solarMonthDays(2025, 2), 28);
      expect(engine.solarMonthDays(2026, 4), 30);
    });

    test('农历每月天数', () {
      expect(engine.lunarMonthDays(2025, 6), 30);
      expect(engine.lunarMonthDays(2025, 5), 29);
      expect(engine.lunarMonthDays(2025, 6, leapMonth: true), 29);
      expect(engine.lunarMonthDays(2026, 6, leapMonth: true), 0);
    });

    test('闰月查询', () {
      expect(engine.leapMonthOf(2025), 6);
      expect(engine.leapMonthOf(2026), 0);
    });
  });

  group('birthDate', () {
    test('公历生日返回出生当年日期', () {
      expect(
        engine.birthDate(
          const BirthdaySpec(
            type: CalendarType.solar,
            month: 5,
            day: 5,
            birthYear: 1990,
          ),
        ),
        d(1990, 5, 5),
      );
    });

    test('公历 2 月 29 日出生返回闰年当天', () {
      expect(
        engine.birthDate(
          const BirthdaySpec(
            type: CalendarType.solar,
            month: 2,
            day: 29,
            birthYear: 2028,
          ),
        ),
        d(2028, 2, 29),
      );
    });

    test('农历生日返回出生当年对应公历日期', () {
      expect(
        engine.birthDate(
          const BirthdaySpec(
            type: CalendarType.lunar,
            month: 6,
            day: 1,
            birthYear: 2025,
          ),
        ),
        d(2025, 6, 25),
      );
    });

    test('闰月生日按闰月返回', () {
      expect(
        engine.birthDate(
          const BirthdaySpec(
            type: CalendarType.lunar,
            month: 6,
            day: 1,
            leapMonth: true,
            preferLeap: true,
            birthYear: 2025,
          ),
        ),
        d(2025, 7, 25),
      );
    });

    test('腊月三十出生跨公历年', () {
      expect(
        engine.birthDate(
          const BirthdaySpec(
            type: CalendarType.lunar,
            month: 12,
            day: 30,
            birthYear: 2025,
          ),
        ),
        d(2026, 2, 16),
      );
    });

    test('未填写出生年份返回 null', () {
      expect(
        engine.birthDate(
          const BirthdaySpec(type: CalendarType.solar, month: 5, day: 5),
        ),
        isNull,
      );
    });
  });
}
