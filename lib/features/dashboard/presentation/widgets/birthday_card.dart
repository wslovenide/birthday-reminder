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
      color: isToday ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
                    _MetaLine(person: person, age: age, zodiac: entry.zodiac),
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
  const _MetaLine({
    required this.person,
    required this.age,
    required this.zodiac,
  });

  final Person person;
  final String? age;
  final String? zodiac;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (person.relationship.isNotEmpty) person.relationship,
      ?zodiac,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cake_rounded, size: 12, color: scheme.onPrimary),
          const SizedBox(width: 3),
          Text(
            '今天',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    final isNear = daysUntil >= 0 && daysUntil <= 7;

    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
        color: isToday
            ? scheme.onPrimaryContainer
            : (isNear ? scheme.primary : scheme.onSurfaceVariant),
        fontWeight: isToday
            ? FontWeight.w800
            : (isNear ? FontWeight.w700 : FontWeight.w600),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
