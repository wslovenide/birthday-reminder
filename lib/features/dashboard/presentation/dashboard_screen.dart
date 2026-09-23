import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/dashboard_entry.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/birthday_card.dart';

/// 首页：按临近程度展示生日列表。
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(filteredEntriesProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final ageDisplay = ref.watch(ageDisplayProvider);
    final relationshipOptions = ref.watch(relationshipOptionsProvider);
    final selectedRelationship = ref.watch(relationshipFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('生日提醒'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: '月份总览',
            onPressed: () => context.push('/months'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/person/new'),
        icon: const Icon(Icons.add),
        label: const Text('添加生日'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsHeader(stats: stats),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '搜索姓名',
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(searchQueryProvider.notifier)
                              .updateQuery('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).updateQuery(value);
                setState(() {});
              },
            ),
          ),
          if (relationshipOptions.length > 1)
            _RelationshipFilterBar(
              options: relationshipOptions,
              selected: selectedRelationship,
              onSelected: (value) =>
                  ref.read(relationshipFilterProvider.notifier).setRelationship(value),
            ),
          Expanded(
            child: entries.isEmpty
                ? _EmptyView(
                    hasAnyPerson: stats.total > 0,
                    onAdd: () => context.push('/person/new'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return BirthdayCard(
                        key: ValueKey(entry.person.id),
                        entry: entry,
                        ageDisplay: ageDisplay,
                        onTap: () => context.push('/person/${entry.person.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(label: '本月寿星', value: stats.thisMonthCount),
          ),
          Expanded(
            child: _StatTile(label: '今年未过', value: stats.upcomingThisYearCount),
          ),
          Expanded(
            child: _StatTile(label: '今年已过', value: stats.passedThisYearCount),
          ),
          Expanded(
            child: _StatTile(label: '全部', value: stats.total),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationshipFilterBar extends StatelessWidget {
  const _RelationshipFilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('全部'),
              selected: selected == null || selected!.isEmpty,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final option in options)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onSelected(selected == option ? null : option),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasAnyPerson, required this.onAdd});

  final bool hasAnyPerson;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasAnyPerson ? Icons.search_off : Icons.cake_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyPerson ? '没有匹配的联系人' : '还没有添加任何生日',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyPerson ? '换个关键词或清除筛选试试' : '记录家人朋友的农历或公历生日，再也不错过',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!hasAnyPerson) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('添加第一位'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
