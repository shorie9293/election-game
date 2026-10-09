import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/reminder/data/election_reminder_repository.dart';
import 'package:election_game/features/reminder/domain/election_reminder_schedule_service.dart';
import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:election_game/features/reminder/infrastructure/election_reminder_scheduler.dart';

/// 選挙リマインダーの設定画面。
class ElectionReminderSettingsScreen extends StatefulWidget {
  const ElectionReminderSettingsScreen({
    super.key,
    ElectionReminderRepository? repository,
    ElectionReminderScheduler? scheduler,
    DateTime Function()? now,
  })  : _repository = repository,
        _scheduler = scheduler,
        _now = now;

  final ElectionReminderRepository? _repository;
  final ElectionReminderScheduler? _scheduler;
  final DateTime Function()? _now;

  @override
  State<ElectionReminderSettingsScreen> createState() =>
      _ElectionReminderSettingsScreenState();
}

class _ElectionReminderSettingsScreenState
    extends State<ElectionReminderSettingsScreen> {
  static const _scheduleService = ElectionReminderScheduleService();
  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  late final ElectionReminderRepository _repository;
  late final ElectionReminderScheduler _scheduler;
  late final DateTime Function() _now;

  bool _loading = true;
  ElectionReminderSettings _settings = ElectionReminderSettings.defaults();

  @override
  void initState() {
    super.initState();
    _repository = widget._repository ?? HiveElectionReminderRepository();
    _scheduler = widget._scheduler ?? ElectionNotificationScheduler();
    _now = widget._now ?? DateTime.now;
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.reminderSettingsScreen,
      appBar: AppBar(title: const Text('通知設定')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '決めた時刻に選挙区の状況を促す通知をお届けします。'
                  '曜日と時刻を自由に設定できます。',
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('現在の状態'),
                  subtitle: Text(
                    _statusLabel(),
                    key: AppKeys.reminderStatusLabel,
                  ),
                ),
                SwitchListTile(
                  key: AppKeys.reminderEnabledSwitch,
                  title: const Text('選挙リマインダー'),
                  subtitle: const Text('毎日の選挙の時刻に通知します'),
                  value: _settings.enabled,
                  onChanged: (value) =>
                      setState(() => _settings = _settings.copyWith(enabled: value)),
                ),
                ListTile(
                  title: const Text('通知時刻'),
                  trailing: Text(
                    _scheduleService.timeLabel(_settings.hour, _settings.minute),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: AppKeys.reminderHourDropdown,
                        value: _settings.hour,
                        decoration: const InputDecoration(labelText: '時'),
                        items: [
                          for (var h = 0; h <= 23; h++)
                            DropdownMenuItem(value: h, child: Text('$h')),
                        ],
                        onChanged: (h) {
                          if (h == null) return;
                          setState(() => _settings = _settings.copyWith(hour: h));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: AppKeys.reminderMinuteDropdown,
                        value: _settings.minute,
                        decoration: const InputDecoration(labelText: '分'),
                        items: [
                          for (final m in _minuteChoices)
                            DropdownMenuItem(value: m, child: Text('$m')),
                        ],
                        onChanged: (m) {
                          if (m == null) return;
                          setState(() => _settings = _settings.copyWith(minute: m));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('通知する曜日'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var weekday = 1; weekday <= 7; weekday++)
                      FilterChip(
                        key: AppKeys.reminderWeekdayChip(weekday),
                        label: Text(_weekdayLabels[weekday - 1]),
                        selected: _settings.weekdays.contains(weekday),
                        onSelected: (selected) => _toggleWeekday(weekday, selected),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('通知の種類'),
                for (final kind in ElectionNotificationKind.values)
                  SwitchListTile(
                    key: AppKeys.reminderKindSwitch(kind.name),
                    title: Text(kind.label),
                    subtitle: Text(kind.description),
                    value: _settings.isKindEnabled(kind),
                    onChanged: (_) =>
                        setState(() => _settings = _settings.toggleKind(kind)),
                  ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('次回の通知'),
                  subtitle: Text(_nextLabel()),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: AppKeys.reminderSaveButton,
                  onPressed: _save,
                  child: const Text('保存'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: AppKeys.reminderTestButton,
                  onPressed: _sendTest,
                  child: const Text('テスト通知を送る'),
                ),
                const SizedBox(height: 24),
                const Text(
                  '通知が届かない場合は端末の設定で通知を許可してください',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
    );
  }

  static const List<int> _minuteOptions = [
    0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55,
  ];

  /// 5分刻み + 現在値（範囲外の分が設定されている場合に備える）。
  List<int> get _minuteChoices {
    if (_minuteOptions.contains(_settings.minute)) return _minuteOptions;
    return [..._minuteOptions, _settings.minute]..sort();
  }

  String _statusLabel() {
    if (!_settings.enabled) return '通知は無効です';
    final label = _scheduleService.weekdayLabel(_settings.weekdays);
    final time = _scheduleService.timeLabel(_settings.hour, _settings.minute);
    return '$label $time';
  }

  String _nextLabel() {
    if (!_settings.enabled) return '通知は無効です';
    if (_settings.weekdays.isEmpty) return '通知日が未選択です';
    final next = _scheduleService.nextOccurrence(_settings, _now());
    if (next == null) return '通知は無効です';
    final y = next.year.toString().padLeft(4, '0');
    final m = next.month.toString().padLeft(2, '0');
    final d = next.day.toString().padLeft(2, '0');
    final hh = next.hour.toString().padLeft(2, '0');
    final mm = next.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }

  void _toggleWeekday(int weekday, bool selected) {
    final set = Set<int>.from(_settings.weekdays);
    if (selected) {
      set.add(weekday);
    } else {
      set.remove(weekday);
    }
    final sorted = set.toList()..sort();
    setState(() => _settings = _settings.copyWith(weekdays: sorted));
  }

  Future<void> _save() async {
    await _repository.save(_settings);
    await _scheduler.apply(_settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('保存しました')));
  }

  Future<void> _sendTest() async {
    try {
      await _scheduler.sendTestNotification();
    } catch (_) {
      // テスト通知の失敗で画面がクラッシュしないよう握り潰す。
    }
  }
}
