import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../calendar/domain/occurrence.dart';
import '../../persons/domain/person.dart';
import '../../persons/providers/person_controller.dart';
import '../../persons/providers/person_providers.dart';
import '../../reminders/providers/reminder_providers.dart';
import '../domain/dashboard_entry.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/person_avatar.dart';

/// 联系人详情页。
class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(personByIdProvider(personId));
    final ageDisplay = ref.watch(ageDisplayProvider);
    final engine = ref.watch(calendarEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('生日详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑',
            onPressed: () => context.push('/person/$personId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: personAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败：$error')),
        data: (person) {
          if (person == null) {
            return const Center(child: Text('联系人不存在'));
          }
          final now = ref.watch(clockProvider)();
          final occurrence = engine.nextOccurrence(person.birthday, now);
          final plans = ref.watch(personReminderPlansProvider(personId));
          final age = ageLabel(occurrence, ageDisplay);
          final birthInfo = buildBirthInfo(person.birthday, engine);
          final zodiac = zodiacLabel(person.birthday, engine);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              _HeroCard(person: person, occurrence: occurrence),
              const SizedBox(height: 16),
              _Section(
                title: '生日信息',
                children: [
                  _InfoRow(label: '出生年份', value: birthInfo.year),
                  _InfoRow(label: '农历', value: birthInfo.lunar),
                  _InfoRow(label: '公历', value: birthInfo.solar),
                  if (zodiac != null) _InfoRow(label: '属相', value: zodiac),
                  if (age != null) _InfoRow(label: '年龄', value: age),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: '下一次生日',
                children: [
                  _InfoRow(
                    label: '倒计时',
                    value: countdownLabel(occurrence.daysUntil),
                  ),
                  _InfoRow(
                    label: '公历',
                    value:
                        '${occurrence.date.year}年${occurrence.date.month}月${occurrence.date.day}日',
                  ),
                  _InfoRow(label: '农历', value: occurrence.lunar.label),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: '提醒',
                children: [
                  _InfoRow(
                    label: '状态',
                    value: person.reminderEnabled ? '已开启' : '已关闭',
                  ),
                  _InfoRow(
                    label: '提前天数',
                    value: person.reminderOffsets.isEmpty
                        ? '未设置'
                        : (person.reminderOffsets.toList()..sort())
                              .map((d) => d == 0 ? '当天' : '$d 天前')
                              .join('、'),
                  ),
                  if (person.reminderEnabled && plans.isNotEmpty)
                    _InfoRow(
                      label: '下一次提醒',
                      value: _formatDateTime(plans.first.scheduledAt),
                    ),
                ],
              ),
              if (person.note.isNotEmpty) ...[
                const SizedBox(height: 16),
                _Section(
                  title: '备注',
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(person.note),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/person/$personId/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除联系人'),
        content: const Text('确定要删除这位联系人及其提醒吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(personControllerProvider).delete(personId);
    if (context.mounted) context.pop();
  }

  String _formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}年${value.month}月${value.day}日 ${two(value.hour)}:${two(value.minute)}';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// 详情页顶部英雄卡：品牌渐变底 + 头像、姓名、关系与下一次生日倒计时。
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.person, required this.occurrence});

  final Person person;
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = occurrence.isToday;
    final days = occurrence.daysUntil;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: PersonAvatar(
              name: person.name,
              avatarPath: person.avatarPath,
              radius: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (person.relationship.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          person.relationship,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (isToday)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cake_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '生日快乐',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$days',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '天后',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 2),
                Text(
                  '${occurrence.date.month}月${occurrence.date.day}日 · '
                  '${occurrence.lunar.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
