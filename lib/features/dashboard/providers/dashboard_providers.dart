import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persons/domain/person.dart';
import '../../persons/domain/person_query.dart';
import '../../persons/domain/relationship.dart';
import '../../persons/providers/person_providers.dart';
import '../../reminders/providers/reminder_providers.dart';
import '../../settings/domain/age_display.dart';
import '../domain/dashboard_entry.dart';

/// 可注入的时钟，便于测试固定"今天"。
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class RelationshipFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setRelationship(String? value) => state = value;
}

final relationshipFilterProvider =
    NotifierProvider<RelationshipFilterNotifier, String?>(
      RelationshipFilterNotifier.new,
    );

/// 全部生日记录，按倒计时排序。
final dashboardEntriesProvider = Provider<List<DashboardEntry>>((ref) {
  final persons = ref.watch(personsProvider).value ?? const <Person>[];
  final engine = ref.watch(calendarEngineProvider);
  final now = ref.watch(clockProvider)();
  final entries = persons
      .map(
        (person) => DashboardEntry(
          person: person,
          occurrence: engine.nextOccurrence(person.birthday, now),
        ),
      )
      .toList();
  return sortDashboardEntries(entries);
});

/// 经过搜索与关系筛选后的记录。
final filteredEntriesProvider = Provider<List<DashboardEntry>>((ref) {
  final entries = ref.watch(dashboardEntriesProvider);
  final query = ref.watch(searchQueryProvider);
  final relationship = ref.watch(relationshipFilterProvider);
  if (query.trim().isEmpty && (relationship == null || relationship.isEmpty)) {
    return entries;
  }
  final matchedIds = filterPersons(
    entries.map((entry) => entry.person).toList(),
    query: query,
    relationship: relationship,
  ).map((person) => person.id).toSet();
  return entries.where((entry) => matchedIds.contains(entry.person.id)).toList();
});

/// 统计概览。
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final persons = ref.watch(personsProvider).value ?? const <Person>[];
  final engine = ref.watch(calendarEngineProvider);
  final now = ref.watch(clockProvider)();
  final today = DateTime(now.year, now.month, now.day);

  var thisMonth = 0;
  var passed = 0;
  var upcoming = 0;
  for (final person in persons) {
    final occurrence = engine.nextOccurrence(person.birthday, now);
    if (occurrence.date.month == now.month) thisMonth++;

    final inYear = engine.birthdayInSolarYear(person.birthday, now.year);
    if (inYear != null && inYear.isBefore(today)) {
      passed++;
    } else {
      upcoming++;
    }
  }
  return DashboardStats(
    total: persons.length,
    thisMonthCount: thisMonth,
    passedThisYearCount: passed,
    upcomingThisYearCount: upcoming,
  );
});

/// 年龄显示方式（来自设置）。
final ageDisplayProvider = Provider<AgeDisplay>((ref) {
  return ref.watch(settingsProvider).value?.ageDisplay ??
      AgeDisplay.actual;
});

/// 按公历月份分组的生日分布。
final monthlyDistributionProvider =
    Provider<Map<int, List<DashboardEntry>>>((ref) {
      final entries = ref.watch(dashboardEntriesProvider);
      final result = <int, List<DashboardEntry>>{
        for (var month = 1; month <= 12; month++) month: <DashboardEntry>[],
      };
      for (final entry in entries) {
        result[entry.occurrence.date.month]!.add(entry);
      }
      return result;
    });

/// 关系筛选项：预设 + 数据中出现的自定义值。
final relationshipOptionsProvider = Provider<List<String>>((ref) {
  final persons = ref.watch(personsProvider).value ?? const <Person>[];
  final custom = persons
      .map((person) => person.relationship)
      .where((value) => value.isNotEmpty);
  return <String>{...Relationships.presets, ...custom}.toList();
});
