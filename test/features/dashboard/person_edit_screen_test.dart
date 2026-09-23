import 'package:birth_remind/features/dashboard/presentation/person_edit_screen.dart';
import 'package:birth_remind/features/persons/data/app_database.dart';
import 'package:birth_remind/features/persons/data/drift_person_repository.dart';
import 'package:birth_remind/features/persons/providers/person_providers.dart';
import 'package:birth_remind/features/settings/data/drift_settings_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftPersonRepository personRepository;
  late DriftSettingsRepository settingsRepository;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    personRepository = DriftPersonRepository(db);
    settingsRepository = DriftSettingsRepository(db);
  });

  tearDown(() => db.close());

  // 使用较高的画布，确保底部网格选择器能完整构建（接近真机高度）。
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget harness() {
    return ProviderScope(
      overrides: [
        personRepositoryProvider.overrideWith((ref) => personRepository),
        settingsRepositoryProvider.overrideWith((ref) => settingsRepository),
      ],
      child: const MaterialApp(home: PersonEditScreen()),
    );
  }

  testWidgets('渲染关系标签、月份/日期选择器与固定在底部的按钮', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '家人'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '朋友'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '同事'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '其他'), findsOneWidget);

    expect(find.text('1 月'), findsOneWidget);
    expect(find.text('1 日'), findsOneWidget);

    // 主按钮常驻在底部，无需滚动到底即可见。
    expect(find.text('添加'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('点击月份弹出网格选择器并可选择', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 月'));
    await tester.pumpAndSettle();

    expect(find.text('选择月份'), findsOneWidget);
    expect(find.text('12月'), findsOneWidget);

    await tester.tap(find.text('5月'));
    await tester.pumpAndSettle();

    expect(find.text('5 月'), findsOneWidget);
  });

  testWidgets('农历日期选项上限为 30（不出现 31 日）', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 日'));
    await tester.pumpAndSettle();

    expect(find.text('选择日期'), findsOneWidget);
    expect(find.text('30日'), findsOneWidget);
    expect(find.text('31日'), findsNothing);

    await tester.tap(find.text('30日'));
    await tester.pumpAndSettle();

    expect(find.text('30 日'), findsOneWidget);
  });

  testWidgets('切换到公历后日期可选到 31 日', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('公历'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1 日'));
    await tester.pumpAndSettle();

    expect(find.text('31日'), findsOneWidget);
  });

  testWidgets('选择「其他」显示自定义关系输入框', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '其他'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '自定义关系'), findsOneWidget);
  });
}
