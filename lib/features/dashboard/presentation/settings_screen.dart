import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../backup/domain/backup_format_exception.dart';
import '../../backup/domain/backup_service.dart';
import '../../backup/providers/backup_providers.dart';
import '../../calendar/domain/calendar_type.dart';
import '../../reminders/providers/reminder_providers.dart';
import '../../settings/domain/age_display.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/providers/settings_providers.dart';

/// 设置页：默认项、提醒、年龄显示、主题、通知权限与备份。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<int> _offsetChoices = [0, 1, 2, 3, 5, 7, 15, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final controller = ref.read(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SectionTitle('默认历法'),
          SegmentedButton<CalendarType>(
            segments: const [
              ButtonSegment(value: CalendarType.lunar, label: Text('农历')),
              ButtonSegment(value: CalendarType.solar, label: Text('公历')),
            ],
            selected: {settings.defaultCalendarType},
            onSelectionChanged: (selection) => controller.save(
              settings.copyWith(defaultCalendarType: selection.first),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('默认提前提醒'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final offset in _offsetChoices)
                FilterChip(
                  label: Text(offset == 0 ? '当天' : '$offset 天前'),
                  selected: settings.defaultReminderOffsets.contains(offset),
                  onSelected: (selected) {
                    final Set<int> next = {...settings.defaultReminderOffsets};
                    if (selected) {
                      next.add(offset);
                    } else {
                      next.remove(offset);
                    }
                    controller.save(settings.copyWith(defaultReminderOffsets: next));
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('提醒时刻'),
          _TileCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('每天提醒时间'),
              subtitle: const Text('提醒将在该时刻送达'),
              trailing: Text(
                TimeOfDay(
                  hour: settings.reminderHour,
                  minute: settings.reminderMinute,
                ).format(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: () => _pickTime(context, ref, settings),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('年龄显示'),
          SegmentedButton<AgeDisplay>(
            segments: const [
              ButtonSegment(value: AgeDisplay.none, label: Text('不显示')),
              ButtonSegment(value: AgeDisplay.actual, label: Text('周岁')),
              ButtonSegment(value: AgeDisplay.xuSui, label: Text('虚岁')),
            ],
            selected: {settings.ageDisplay},
            onSelectionChanged: (selection) => controller.save(
              settings.copyWith(ageDisplay: selection.first),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('主题'),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(value: AppThemeMode.system, label: Text('跟随系统')),
              ButtonSegment(value: AppThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: AppThemeMode.dark, label: Text('深色')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) => controller.save(
              settings.copyWith(themeMode: selection.first),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('通知'),
          _TileCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('通知权限'),
              subtitle: const Text('未收到提醒时，请检查系统通知权限'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _requestPermission(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('数据备份'),
          _TileCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('导出备份'),
                  subtitle: const Text('导出为 JSON 文件并分享'),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('导入备份'),
                  subtitle: const Text('从 JSON 文件恢复数据'),
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '生日提醒 · 数据仅保存在本机',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      ),
    );
    if (picked == null) return;
    await ref.read(settingsControllerProvider).save(
      settings.copyWith(
        reminderHour: picked.hour,
        reminderMinute: picked.minute,
      ),
    );
  }

  Future<void> _requestPermission(BuildContext context, WidgetRef ref) async {
    final granted = await ref
        .read(reminderControllerProvider)
        .ensurePermission();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted ? '通知权限已授予' : '未获得通知权限，请在系统设置中手动开启',
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}'
          'birth_remind_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      await ref.read(backupControllerProvider).exportToFile(path);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: '生日提醒备份',
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败：$error')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = file?.path;
    if (path == null || !context.mounted) return;

    final strategy = await showDialog<ImportStrategy>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入方式'),
        content: const Text('合并会跳过已存在的联系人；覆盖会清空现有数据后再导入。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ImportStrategy.merge),
            child: const Text('合并'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ImportStrategy.overwrite),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );
    if (strategy == null) return;

    try {
      final imported = await ref
          .read(backupControllerProvider)
          .importFromFile(path, strategy: strategy);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '导入完成：新增 ${imported.added} 位，'
            '跳过 ${imported.skipped} 位，清除 ${imported.removed} 位',
          ),
        ),
      );
    } on BackupFormatException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
