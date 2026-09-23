import 'package:flutter/material.dart';

import '../../../persons/domain/person.dart';
import '../../../settings/domain/age_display.dart';
import '../../domain/dashboard_entry.dart';
import 'person_avatar.dart';

/// 生日列表中的一张卡片。
class BirthdayCard extends StatelessWidget {
  const BirthdayCard({
    super.key,
    required this.entry,
    required this.ageDisplay,
    this.onTap,
  });

  final DashboardEntry entry;
  final AgeDisplay ageDisplay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final person = entry.person;
    final occurrence = entry.occurrence;
    final isToday = occurrence.isToday;
    final age = ageLabel(occurrence, ageDisplay);

    return Card(
      color: isToday ? scheme.primaryContainer : scheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PersonAvatar(name: person.name, avatarPath: person.avatarPath),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            person.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          _TodayBadge(scheme: scheme),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      birthdayDateLabel(person, occurrence),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MetaLine(
                      person: person,
                      age: age,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Countdown(
                daysUntil: occurrence.daysUntil,
                isToday: isToday,
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.person, required this.age});

  final Person person;
  final String? age;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (person.relationship.isNotEmpty) person.relationship,
      ?age,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '今天',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({
    required this.daysUntil,
    required this.isToday,
    required this.scheme,
  });

  final int daysUntil;
  final bool isToday;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = countdownLabel(daysUntil);
    final isNear = daysUntil <= 3;

    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        color: isToday
            ? scheme.onPrimaryContainer
            : (isNear ? scheme.primary : scheme.onSurfaceVariant),
        fontWeight: isToday || isNear ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
