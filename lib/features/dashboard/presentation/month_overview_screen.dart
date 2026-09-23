import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/dashboard_entry.dart';
import '../providers/dashboard_providers.dart';

/// 按月份浏览生日分布。
class MonthOverviewScreen extends ConsumerWidget {
  const MonthOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distribution = ref.watch(monthlyDistributionProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: const Text('月份总览')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (var month = 1; month <= 12; month++)
            _MonthSection(
              month: month,
              entries: distribution[month] ?? const [],
              isCurrent: month == now.month,
            ),
        ],
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.month,
    required this.entries,
    required this.isCurrent,
  });

  final int month;
  final List<DashboardEntry> entries;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$month 月',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (isCurrent)
                  Text(
                    '本月',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const Spacer(),
                Text(
                  '${entries.length} 位',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                '本月暂无生日',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in entries)
                    ActionChip(
                      avatar: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          '${entry.occurrence.date.day}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      label: Text(entry.person.name),
                      onPressed: () =>
                          context.push('/person/${entry.person.id}'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
