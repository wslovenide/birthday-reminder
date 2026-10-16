import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../calendar/domain/calendar_engine.dart';
import '../../persons/providers/person_providers.dart';
import '../domain/dashboard_entry.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/birthday_card.dart';
import 'widgets/person_avatar.dart';

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
    final engine = ref.watch(calendarEngineProvider);
    final now = ref.watch(clockProvider)();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/person/new'),
          icon: const Icon(Icons.add),
          label: const Text('添加生日'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderArea(
              now: now,
              engine: engine,
              heroEntry: entries.isEmpty ? null : entries.first,
              onHeroTap: entries.isEmpty
                  ? null
                  : () => context.push('/person/${entries.first.person.id}'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _StatsHeader(stats: stats),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: '搜索姓名',
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
                onSelected: (value) => ref
                    .read(relationshipFilterProvider.notifier)
                    .setRelationship(value),
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
                        return _StaggerIn(
                          index: index,
                          child: BirthdayCard(
                            key: ValueKey(entry.person.id),
                            entry: entry,
                            ageDisplay: ageDisplay,
                            onTap: () =>
                                context.push('/person/${entry.person.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 品牌渐变问候区：时间问候 + 今日日期（含农历）+ 最近生日主角卡。
class _HeaderArea extends StatelessWidget {
  const _HeaderArea({
    required this.now,
    required this.engine,
    required this.heroEntry,
    this.onHeroTap,
  });

  final DateTime now;
  final CalendarEngine engine;
  final DashboardEntry? heroEntry;
  final VoidCallback? onHeroTap;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: AppTheme.headerGradient,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      decoration: const BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(now.hour),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateLabel(now),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    color: Colors.white,
                    tooltip: '月份总览',
                    onPressed: () => context.push('/months'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: Colors.white,
                    tooltip: '设置',
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              if (heroEntry != null) ...[
                const SizedBox(height: 10),
                _NextBirthdayHero(entry: heroEntry!, onTap: onHeroTap),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 5) return '夜深了';
    if (hour < 11) return '早上好';
    if (hour < 13) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _dateLabel(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${date.month}月${date.day}日 周${weekdays[date.weekday - 1]} · '
        '${engine.toLunar(date).label}';
  }
}

/// 最近一个生日的主角卡：半透明白叠加在渐变上。
class _NextBirthdayHero extends StatelessWidget {
  const _NextBirthdayHero({required this.entry, this.onTap});

  final DashboardEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final person = entry.person;
    final isToday = entry.occurrence.isToday;
    final days = entry.occurrence.daysUntil;

    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              PersonAvatar(
                name: person.name,
                avatarPath: person.avatarPath,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (person.relationship.isNotEmpty)
                      Text(
                        person.relationship,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              ),
              if (isToday)
                Row(
                  children: [
                    const Icon(
                      Icons.cake_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '生日快乐',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$days',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '天后',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 仪表盘统计概览行。
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
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

/// 列表项入场动画：淡入 + 上滑，按位置交错。
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delaySteps = index.clamp(0, 5);
    final duration = Duration(milliseconds: 300 + delaySteps * 36);
    final begin = delaySteps * 36 / (300 + delaySteps * 36);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Interval(begin, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
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
                onSelected: (_) =>
                    onSelected(selected == option ? null : option),
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
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasAnyPerson ? Icons.search_off_rounded : Icons.cake_rounded,
                size: 44,
                color: theme.colorScheme.primary,
              ),
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
