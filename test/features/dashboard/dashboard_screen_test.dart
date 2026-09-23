import 'package:birth_remind/features/calendar/domain/birthday_spec.dart';
import 'package:birth_remind/features/calendar/domain/calendar_type.dart';
import 'package:birth_remind/features/dashboard/presentation/dashboard_screen.dart';
import 'package:birth_remind/features/dashboard/presentation/widgets/birthday_card.dart';
import 'package:birth_remind/features/dashboard/providers/dashboard_providers.dart';
import 'package:birth_remind/features/persons/domain/person.dart';
import 'package:birth_remind/features/persons/providers/person_providers.dart';
import 'package:birth_remind/features/reminders/providers/reminder_providers.dart';
import 'package:birth_remind/features/settings/domain/age_display.dart';
import 'package:birth_remind/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 1, 8, 0);

  Person buildPerson({
    required int id,
    required String name,
    String relationship = '',
    CalendarType type = CalendarType.solar,
    int month = 5,
    int day = 1,
    int? birthYear,
  }) {
    return Person(
      id: id,
      name: name,
      relationship: relationship,
      birthday: BirthdaySpec(
        type: type,
        month: month,
        day: day,
        birthYear: birthYear,
      ),
      reminderOffsets: const {0},
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  // Bob 今天、Carol 明天、Alice 农历八月十五。
  final persons = [
    buildPerson(
      id: 1,
      name: 'Alice',
      relationship: '朋友',
      type: CalendarType.lunar,
      month: 8,
      day: 15,
    ),
    buildPerson(id: 2, name: 'Bob', relationship: '朋友', birthYear: 1990),
    buildPerson(id: 3, name: 'Carol', relationship: '家人', day: 2),
  ];

  Widget harness({
    List<Person>? people,
    AgeDisplay ageDisplay = AgeDisplay.actual,
  }) {
    return ProviderScope(
      overrides: [
        personsProvider.overrideWith(
          (ref) => Stream.value(people ?? persons),
        ),
        clockProvider.overrideWith((ref) => () => now),
        settingsProvider.overrideWith(
          (ref) => Stream.value(AppSettings(ageDisplay: ageDisplay)),
        ),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  testWidgets('今日寿星置顶且按倒计时升序排列', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<BirthdayCard>(find.byType(BirthdayCard))
        .toList();
    expect(
      cards.map((card) => card.entry.person.name).toList(),
      ['Bob', 'Carol', 'Alice'],
    );
    expect(cards.first.entry.occurrence.isToday, isTrue);
  });

  testWidgets('倒计时文案正确', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsNWidgets(2)); // 徽标 + 倒计时
    expect(find.text('明天'), findsOneWidget);
    expect(find.text('还有 147 天'), findsOneWidget);
  });

  testWidgets('农历生日同时展示农历日期', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('农历八月十五'), findsOneWidget);
  });

  testWidgets('按设置显示周岁年龄', (tester) async {
    await tester.pumpWidget(harness(ageDisplay: AgeDisplay.actual));
    await tester.pumpAndSettle();

    expect(find.textContaining('36 岁'), findsOneWidget);
  });

  testWidgets('关闭年龄显示时不出现年龄', (tester) async {
    await tester.pumpWidget(harness(ageDisplay: AgeDisplay.none));
    await tester.pumpAndSettle();

    expect(find.textContaining('36 岁'), findsNothing);
  });

  testWidgets('搜索按姓名过滤列表', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'caro');
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<BirthdayCard>(find.byType(BirthdayCard))
        .toList();
    expect(cards.map((card) => card.entry.person.name), ['Carol']);
  });

  testWidgets('按关系筛选列表', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '家人'));
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<BirthdayCard>(find.byType(BirthdayCard))
        .toList();
    expect(cards.map((card) => card.entry.person.name), ['Carol']);
  });

  testWidgets('无联系人时展示引导文案', (tester) async {
    await tester.pumpWidget(harness(people: const []));
    await tester.pumpAndSettle();

    expect(find.text('还没有添加任何生日'), findsOneWidget);
    expect(find.text('添加第一位'), findsOneWidget);
  });
}
