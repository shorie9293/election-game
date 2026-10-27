import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/reminder/data/quiet_hours_repository.dart';
import 'package:election_game/features/reminder/domain/quiet_hours.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';

/// 静穏時間（おやすみモード）の設定画面。
///
/// リポジトリ・現在時刻は注入可能（試練で Hive に触れずに検証するため）。
/// 保存時は必ず [QuietHoursRepository.save] に到達してから再読込する。
class QuietHoursSettingsScreen extends StatefulWidget {
  const QuietHoursSettingsScreen({
    super.key,
    QuietHoursRepository? repository,
    DateTime Function()? now,
    ValueChanged<QuietHoursSettings>? onSaved,
  })  : _repository = repository,
        _now = now,
        _onSaved = onSaved;

  final QuietHoursRepository? _repository;
  final DateTime Function()? _now;
  final ValueChanged<QuietHoursSettings>? _onSaved;

  @override
  State<QuietHoursSettingsScreen> createState() =>
      _QuietHoursSettingsScreenState();
}

class _QuietHoursSettingsScreenState extends State<QuietHoursSettingsScreen> {
  late final QuietHoursRepository _repository =
      widget._repository ?? HiveQuietHoursRepository();

  bool _loaded = false;
  QuietHoursSettings _settings = QuietHoursSettings.defaults();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final toSave = _settings;
    await _repository.save(toSave);
    await _load();
    widget._onSaved?.call(toSave);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('静穏時間を保存しました')));
  }

  /// 現在時刻（注入された関数か実時刻）。判定は分単位。
  DateTime get _now => (widget._now ?? DateTime.now)();

  String get _previewText {
    final s = _settings;
    if (!s.enabled) return '静穏時間は無効です';
    if (s.isInactiveRange) {
      return '開始と終了が同じため通知は抑止されません';
    }
    if (s.policy == QuietHoursPolicy.skip) {
      return '${s.label} の通知は行いません';
    }
    final when = s.isOvernight ? '翌朝 ${s.endLabel}' : s.endLabel;
    return '${s.label} の通知は$when に繰り延べます';
  }

  String get _statusText {
    final s = _settings;
    if (!s.enabled || s.isInactiveRange) return '';
    final within = QuietHoursService.isWithinQuietHours(
      _now,
      s.startMinutes,
      s.endMinutes,
    );
    return within ? 'ただいま静穏時間内です' : 'ただいま静穏時間外です';
  }

  Widget _hourDropdown({
    required Key key,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '時'),
      items: [
        for (var h = 0; h < 24; h++)
          DropdownMenuItem<int>(value: h, child: Text('$h時')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _minuteDropdown({
    required Key key,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final choices = <int>[
      for (var m = 0; m < 60; m += 5) m,
    ];
    if (!choices.contains(value)) {
      choices
        ..add(value)
        ..sort();
    }
    return DropdownButtonFormField<int>(
      key: key,
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: '分'),
      items: [
        for (final m in choices)
          DropdownMenuItem<int>(
            value: m,
            child: Text('${m.toString().padLeft(2, '0')}分'),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      key: AppKeys.quietHoursScreen,
      title: const Text('静穏時間（おやすみモード）'),
    );
    if (!_loaded) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final enabled = _settings.enabled;
    return Scaffold(
      appBar: appBar,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            key: AppKeys.quietHoursEnabledSwitch,
            title: const Text('静穏時間を有効にする'),
            subtitle: const Text('この時間帯の通知を抑止します'),
            value: enabled,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(enabled: v)),
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            Text('開始時刻', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: _hourDropdown(
                    key: AppKeys.quietHoursStartHourDropdown,
                    value: _settings.startHour,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(startHour: v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _minuteDropdown(
                    key: AppKeys.quietHoursStartMinuteDropdown,
                    value: _settings.startMinute,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(startMinute: v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('終了時刻', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: _hourDropdown(
                    key: AppKeys.quietHoursEndHourDropdown,
                    value: _settings.endHour,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(endHour: v),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _minuteDropdown(
                    key: AppKeys.quietHoursEndMinuteDropdown,
                    value: _settings.endMinute,
                    onChanged: (v) => setState(
                      () => _settings = _settings.copyWith(endMinute: v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('静穏時間中の通知', style: Theme.of(context).textTheme.titleSmall),
            for (final policy in QuietHoursPolicy.values)
              RadioListTile<QuietHoursPolicy>(
                key: AppKeys.quietHoursPolicyRadio(policy.storageKey),
                title: Text(policy.label),
                value: policy,
                groupValue: _settings.policy,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _settings = _settings.copyWith(policy: v));
                },
              ),
          ],
          const SizedBox(height: 16),
          Text(
            _previewText,
            key: AppKeys.quietHoursPreview,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_statusText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _statusText,
              key: AppKeys.quietHoursStatus,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            key: AppKeys.quietHoursSaveButton,
            onPressed: _save,
            child: const Text('保存'),
          ),
          const SizedBox(height: 24),
          const Text(
            '静穏時間の設定は選挙リマインダーの通知に反映されます',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
