import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../calendar/domain/birthday_spec.dart';
import '../../calendar/domain/calendar_type.dart';
import '../../persons/domain/person.dart';
import '../../persons/domain/relationship.dart';
import '../../persons/providers/person_controller.dart';
import '../../persons/providers/person_providers.dart';
import 'widgets/person_avatar.dart';

/// 新增或编辑联系人的表单页。
class PersonEditScreen extends ConsumerStatefulWidget {
  const PersonEditScreen({super.key, this.personId});

  final int? personId;

  @override
  ConsumerState<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends ConsumerState<PersonEditScreen> {
  static const List<int> _offsetChoices = [0, 1, 2, 3, 5, 7, 15, 30];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _customRelationshipController =
      TextEditingController();

  CalendarType _type = CalendarType.lunar;
  int _month = 1;
  int _day = 1;
  bool _leapMonth = false;
  bool _preferLeap = false;
  String _relationship = Relationships.family;
  bool _customRelationship = false;
  Set<int> _offsets = {0, 1};
  bool _reminderEnabled = true;
  String? _avatarPath;
  Person? _original;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _yearController.dispose();
    _customRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    if (widget.personId == null) {
      if (!mounted) return;
      setState(() {
        _type = settings.defaultCalendarType;
        _offsets = {...settings.defaultReminderOffsets};
        _loading = false;
      });
      return;
    }

    final person = await ref
        .read(personRepositoryProvider)
        .getById(widget.personId!);
    if (!mounted) return;
    setState(() {
      _original = person;
      if (person != null) {
        _nameController.text = person.name;
        _noteController.text = person.note;
        _yearController.text = person.birthday.birthYear?.toString() ?? '';
        _type = person.birthday.type;
        _month = person.birthday.month;
        _day = person.birthday.day;
        _leapMonth = person.birthday.leapMonth;
        _preferLeap = person.birthday.preferLeap;
        _avatarPath = person.avatarPath;
        _offsets = {...person.reminderOffsets};
        _reminderEnabled = person.reminderEnabled;
        if (Relationships.presets.contains(person.relationship)) {
          _relationship = person.relationship;
        } else if (person.relationship.isNotEmpty) {
          _customRelationship = true;
          _relationship = Relationships.other;
          _customRelationshipController.text = person.relationship;
        }
      }
      _loading = false;
    });
  }

  int get _maxDay {
    final engine = ref.read(calendarEngineProvider);
    if (_type == CalendarType.solar) {
      return engine.solarMonthDays(2000, _month);
    }
    final year =
        int.tryParse(_yearController.text.trim()) ??
        engine.toLunar(DateTime.now()).year;
    var days = engine.lunarMonthDays(
      year,
      _month,
      leapMonth: _leapMonth && _preferLeap,
    );
    if (days == 0) days = engine.lunarMonthDays(year, _month);
    return days == 0 ? 30 : days;
  }

  void _clampDay() {
    final max = _maxDay;
    if (_day > max) _day = max;
  }

  Future<void> _pickAvatar() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    final path = file?.path;
    if (path != null && mounted) {
      setState(() => _avatarPath = path);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final birthday = BirthdaySpec(
      type: _type,
      month: _month,
      day: _day,
      leapMonth: _type == CalendarType.lunar && _leapMonth,
      preferLeap: _type == CalendarType.lunar && _leapMonth && _preferLeap,
      birthYear: int.tryParse(_yearController.text.trim()),
    );
    if (!ref.read(calendarEngineProvider).isValid(birthday)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('生日日期无效，请检查月份与日期')));
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final person = Person(
      id: _original?.id ?? 0,
      name: _nameController.text.trim(),
      relationship: _customRelationship
          ? _customRelationshipController.text.trim()
          : _relationship,
      note: _noteController.text.trim(),
      avatarPath: _avatarPath,
      birthday: birthday,
      reminderOffsets: _offsets,
      reminderEnabled: _reminderEnabled,
      createdAt: _original?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await ref.read(personControllerProvider).save(person);
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickMonth() async {
    final result = await _showNumberPicker(
      title: '选择月份',
      count: 12,
      selected: _month,
      suffix: '月',
    );
    if (result != null && mounted) {
      setState(() {
        _month = result;
        _clampDay();
      });
    }
  }

  Future<void> _pickDay() async {
    final result = await _showNumberPicker(
      title: '选择日期',
      count: _maxDay,
      selected: _day,
      suffix: '日',
    );
    if (result != null && mounted) {
      setState(() => _day = result);
    }
  }

  /// 底部弹出的数字网格选择器。
  Future<int?> _showNumberPicker({
    required String title,
    required int count,
    required int selected,
    required String suffix,
    int columns = 5,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      '当前 $selected$suffix',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: count,
                  itemBuilder: (context, index) {
                    final value = index + 1;
                    final isSelected = value == selected;
                    return Material(
                      color: isSelected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(sheetContext).pop(value),
                        child: Center(
                          child: Text(
                            '$value$suffix',
                            style: TextStyle(
                              color: isSelected
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isEditing = _original != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑生日' : '添加生日')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: Column(
                children: [
                  PersonAvatar(
                    name: _nameController.text,
                    avatarPath: _avatarPath,
                    radius: 40,
                  ),
                  TextButton.icon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('选择头像'),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                hintText: '请输入姓名',
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '请填写姓名' : null,
            ),
            const SizedBox(height: 20),
            Text('关系', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in Relationships.presets)
                  ChoiceChip(
                    label: Text(preset),
                    selected: _relationship == preset,
                    onSelected: (_) => setState(() {
                      _relationship = preset;
                      _customRelationship = preset == Relationships.other;
                    }),
                  ),
              ],
            ),
            if (_customRelationship) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customRelationshipController,
                decoration: const InputDecoration(
                  labelText: '自定义关系',
                  hintText: '如：邻居、老师',
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('生日', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<CalendarType>(
              segments: const [
                ButtonSegment(
                  value: CalendarType.lunar,
                  label: Text('农历'),
                ),
                ButtonSegment(
                  value: CalendarType.solar,
                  label: Text('公历'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  _clampDay();
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: '月份',
                    value: '$_month 月',
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickMonth,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: '日期',
                    value: '$_day 日',
                    icon: Icons.event_outlined,
                    onTap: _pickDay,
                  ),
                ),
              ],
            ),
            if (_type == CalendarType.lunar) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('生于闰月'),
                subtitle: const Text('出生当年该月为闰月'),
                value: _leapMonth,
                onChanged: (value) {
                  setState(() {
                    _leapMonth = value;
                    if (!value) _preferLeap = false;
                    _clampDay();
                  });
                },
              ),
              if (_leapMonth)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('优先在闰月庆祝'),
                  subtitle: const Text('遇到有闰月的年份在闰月过生日，否则按平月'),
                  value: _preferLeap,
                  onChanged: (value) {
                    setState(() {
                      _preferLeap = value;
                      _clampDay();
                    });
                  },
                ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '出生年份（选填）',
                hintText: '填写后可显示年龄，如 1990',
              ),
              onChanged: (_) => setState(_clampDay),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final year = int.tryParse(text);
                if (year == null) return '请输入数字年份';
                if (year < 1901 || year > 2099) return '年份需在 1901-2099 之间';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('提醒', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('启用提醒'),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
            ),
            Opacity(
              opacity: _reminderEnabled ? 1 : 0.5,
              child: IgnorePointer(
                ignoring: !_reminderEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('提前提醒（可多选，0 表示当天）'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final offset in _offsetChoices)
                          FilterChip(
                            label: Text(offset == 0 ? '当天' : '$offset 天前'),
                            selected: _offsets.contains(offset),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _offsets.add(offset);
                                } else {
                                  _offsets.remove(offset);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                hintText: '如：喜欢的礼物、联系方式',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(isEditing ? '保存修改' : '添加'),
          ),
        ),
      ),
    );
  }
}

/// 可点击的字段，点击后弹出选择器。
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 12,
          ),
        ),
        child: Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
