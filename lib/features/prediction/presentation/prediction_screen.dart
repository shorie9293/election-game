import 'package:flutter/material.dart';

import '../../../core/testing/app_keys.dart';
import '../../../domain/models/candidate.dart';
import '../../../domain/models/election.dart';
import '../data/prediction_repository.dart';
import '../domain/election_prediction.dart';
import '../domain/prediction_service.dart';

/// 選挙結果の予想（当選者＋得票率）と、完了済み選挙との答え合わせ画面。
class PredictionScreen extends StatefulWidget {
  final String electionId;
  final String electionTitle;
  final List<Candidate> candidates;

  /// 完了済み選挙。非nullかつ保存済み予想がある場合に答え合わせを表示する。
  final Election? completedElection;

  /// 予想の保存先。既定は SharedPreferencesPredictionRepository。
  final PredictionRepository? repository;

  const PredictionScreen({
    super.key,
    required this.electionId,
    required this.electionTitle,
    required this.candidates,
    this.completedElection,
    this.repository,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  String? _selectedWinnerId;
  int _predictedShare = 50;
  ElectionPrediction? _saved;
  bool _loaded = false;

  /// State再利用時の陳腐化を避けるため、候補者は必ず getter 経由で参照する。
  List<Candidate> get _candidates => widget.candidates;

  PredictionRepository get _repository =>
      widget.repository ?? const SharedPreferencesPredictionRepository();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prediction = await _repository.load(widget.electionId);
    if (!mounted) return;
    setState(() {
      _saved = prediction;
      if (prediction != null) {
        _selectedWinnerId = prediction.predictedWinnerId;
        _predictedShare = prediction.predictedShare;
      }
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final winnerId = _selectedWinnerId;
    if (winnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当選者を選んでください')),
      );
      return;
    }
    final prediction = ElectionPrediction(
      electionId: widget.electionId,
      predictedWinnerId: winnerId,
      predictedShare: _predictedShare,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _repository.save(prediction);
    if (!mounted) return;
    setState(() => _saved = prediction);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('予想を保存しました')),
    );
  }

  /// 答え合わせカードを構築する。
  ///
  /// 完了済み選挙と保存済み予想の両方が揃っている場合のみ表示する。
  Widget? _buildOutcomeCard() {
    final completed = widget.completedElection;
    final saved = _saved;
    if (completed == null || saved == null) return null;

    final outcome = PredictionService.evaluate(saved, completed);
    final actualWinnerName = completed.candidates
        .firstWhere(
          (c) => c.id == outcome.actualWinnerId,
          orElse: () => completed.candidates.first,
        )
        .name;

    return Card(
      key: AppKeys.predictionOutcomeCard,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '答え合わせ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('当選者: $actualWinnerName'),
            Text(
              key: AppKeys.predictionWinnerHitBadge,
              outcome.winnerHit ? '的中！' : '外れ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              key: AppKeys.predictionShareErrorLabel,
              '得票率の誤差: ${outcome.shareError}pt',
            ),
            Text(
              key: AppKeys.predictionScoreLabel,
              'スコア: ${outcome.score} / 100',
            ),
            Text(
              key: AppKeys.predictionAccuracyLabel,
              outcome.accuracyLabel,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outcomeCard = _loaded ? _buildOutcomeCard() : null;
    return Scaffold(
      key: AppKeys.predictionScreen,
      appBar: AppBar(
        title: const Text('選挙予想', key: AppKeys.predictionTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.electionTitle),
          const SizedBox(height: 8),
          const Text('当選すると思う候補者を選んでください'),
          ..._candidates.map((candidate) {
            return RadioListTile<String>(
              key: AppKeys.predictionCandidateOption(candidate.id),
              value: candidate.id,
              groupValue: _selectedWinnerId,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedWinnerId = value);
              },
              title: Text(candidate.name),
              subtitle: Text(candidate.faction),
            );
          }),
          Text(
            key: AppKeys.predictionShareLabel,
            '予想得票率: $_predictedShare%',
          ),
          Slider(
            key: AppKeys.predictionShareSlider,
            min: 1,
            max: 100,
            divisions: 99,
            value: _predictedShare.toDouble(),
            label: '$_predictedShare%',
            onChanged: (value) {
              setState(() => _predictedShare = value.round());
            },
          ),
          ElevatedButton(
            key: AppKeys.predictionSaveButton,
            onPressed: _save,
            child: const Text('予想を保存'),
          ),
          const SizedBox(height: 24),
          if (outcomeCard != null) outcomeCard,
        ],
      ),
    );
  }
}
