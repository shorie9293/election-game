import 'package:flutter/material.dart';
import 'package:election_game/domain/models/election_scale.dart';

/// 全画面・全Widgetの試験用Keyを一元管理。
/// 重複禁止。命名規則: <画面名>_<要素名>
class AppKeys {
  AppKeys._();

  // Citizen creation
  static const citizenNameInput = Key('citizen_name_input');
  static const citizenJobSelector = Key('citizen_job_selector');
  static const citizenCreateButton = Key('citizen_create_button');
  static const citizenConcernSelector = Key('citizen_concern_selector');

  // Home
  static const homeTitle = Key('home_title');
  static const homeLifeParams = Key('home_life_params');
  static const homeElectionButton = Key('home_election_button');
  static const homeAdvanceTurnButton = Key('home_advance_turn_button');
  static const homeCountdown = Key('home_countdown');
  static const homeCitizenInfo = Key('home_citizen_info');
  static const homeSocietyMood = Key('home_society_mood');
  static const homeDailyEvent = Key('home_daily_event');
  static const homeActionTalkNpc = Key('home_action_talk_npc');
  static const homeActionGatherInfo = Key('home_action_gather_info');
  static const homeActionRest = Key('home_action_rest');
  static const homeChoiceDialog = Key('home_choice_dialog');
  static const homeChoiceOption = Key('home_choice_option');
  static const homeConcernGrowth = Key('home_concern_growth');

  // Election announcement
  static const electionAnnounceTitle = Key('election_announce_title');
  static const electionCandidateList = Key('election_candidate_list');
  static const electionProceedButton = Key('election_proceed_button');

  // Candidate detail
  static const candidateDetailTitle = Key('candidate_detail_title');
  static const candidatePolicies = Key('candidate_policies');
  static const candidateDetailGroup = Key('candidate_detail_group');

  // Debate
  static const debateTitle = Key('debate_title');
  static const debateSpeechBubble = Key('debate_speech_bubble');
  static const debateCandidateName = Key('debate_candidate_name');
  static const debateAdvanceButton = Key('debate_advance_button');
  static const debateToVoteButton = Key('debate_to_vote_button');

  // Debate reactions
  static const debateReactionAgree = Key('debate_reaction_agree');
  static const debateReactionDisagree = Key('debate_reaction_disagree');
  static const debateReactionQuestion = Key('debate_reaction_question');
  static const debateReactionSilent = Key('debate_reaction_silent');
  static const debateReactionPanel = Key('debate_reaction_panel');

  // Candidate rating
  static const debateRatingPanel = Key('debate_rating_panel');
  static const debateRatingSubmit = Key('debate_rating_submit');
  static Key debateRatingStars(String candidateId) =>
      Key('debate_rating_stars_$candidateId');

  // Vote
  static const voteTitle = Key('vote_title');
  static const voteCandidateList = Key('vote_candidate_list');
  static const voteConfirmButton = Key('vote_confirm_button');
  static const voteAbstainButton = Key('vote_abstain_button');
  static const voteResultNotice = Key('vote_result_notice');

  // Election result
  static const resultTitle = Key('result_title');
  static const resultWinner = Key('result_winner');
  static const resultVoteCounts = Key('result_vote_counts');
  static const resultLifeImpact = Key('result_life_impact');
  static const resultVoteExplanation = Key('result_vote_explanation');
  static const resultWinnerSpeech = Key('result_winner_speech');
  static const resultNpcReactions = Key('result_npc_reactions');
  static const resultContinueButton = Key('result_continue_button');
  static const resultConcernGrowth = Key('result_concern_growth');

  // Town square
  static const townSquareTitle = Key('town_square_title');
  static const townSquareNpcList = Key('town_square_npc_list');
  static const townSquareCloseButton = Key('town_square_close_button');
  static const townSquareDebateButton = Key('town_square_debate_button');
  static const townSquareNpcInfo = Key('town_square_npc_info');

  // Game screen
  static const gameScreenScaffold = Key('game_screen_scaffold');

  // Election archive（選挙アーカイブ）
  static const homeArchiveButton = Key('home_archive_button');
  static const archiveTitle = Key('archive_title');
  static const archiveSummaryCard = Key('archive_summary_card');
  static const archiveEmptyState = Key('archive_empty_state');
  static const archiveList = Key('archive_list');
  static const archiveScaleProgression = Key('archive_scale_progression');
  static const archiveFilterAll = Key('archive_filter_all');
  static Key archiveScaleFilter(ElectionScale scale) =>
      Key('archive_scale_filter_${scale.name}');

  // Quiz（政策・制度クイズ）
  static const homeQuizButton = Key('home_quiz_button');
  static const quizTitle = Key('quiz_title');
  static const quizProgress = Key('quiz_progress');
  static const quizCategory = Key('quiz_category');
  static const quizQuestionText = Key('quiz_question_text');
  static Key quizChoice(int index) => Key('quiz_choice_$index');
  static const quizFeedback = Key('quiz_feedback');
  static const quizExplanation = Key('quiz_explanation');
  static const quizNextButton = Key('quiz_next_button');
  static const quizResultView = Key('quiz_result_view');
  static const quizResultScore = Key('quiz_result_score');
  static const quizResultRank = Key('quiz_result_rank');
  static const quizResultBadge = Key('quiz_result_badge');
  static const quizResultMissed = Key('quiz_result_missed');
  static const quizBestScore = Key('quiz_best_score');
  static const quizRetryButton = Key('quiz_retry_button');
  static const quizCloseButton = Key('quiz_close_button');

  // Ending
  static const endingConcernGrowth = Key('ending_concern_growth');

  // Tutorial overlay
  static const tutorialOverlay = Key('tutorial_overlay');
  static const tutorialNextButton = Key('tutorial_next_button');
  static const tutorialSkipButton = Key('tutorial_skip_button');
  static const tutorialText = Key('tutorial_text');

  // Text scale（文字サイズ設定）
  static const textScaleScreenScaffold = Key('text_scale_screen_scaffold');
  static const textScaleSampleCard = Key('text_scale_sample_card');
  static const homeTextScaleButton = Key('home_text_scale_button');
  static Key textScaleOption(double scale) => Key('text_scale_$scale');

  // Support simulation（支持率シミュレーション）
  static const homeSupportButton = Key('home_support_button');
  static const supportTitle = Key('support_title');
  static const supportMoodCard = Key('support_mood_card');
  static const supportVoterCount = Key('support_voter_count');
  static const supportLeaderCard = Key('support_leader_card');
  static const supportEmptyState = Key('support_empty_state');
  static const supportNote = Key('support_note');
  static Key supportCandidateRow(String candidateId) =>
      Key('support_candidate_row_$candidateId');
  static Key supportCandidateRate(String candidateId) =>
      Key('support_candidate_rate_$candidateId');
  static Key supportCandidateJob(String candidateId) =>
      Key('support_candidate_job_$candidateId');

  // Candidate almanac（候補者名鑑）
  static const homeAlmanacButton = Key('home_almanac_button');
  static const almanacTitle = Key('almanac_title');
  static const almanacSearchField = Key('almanac_search_field');
  static const almanacFactionAll = Key('almanac_faction_all');
  static Key almanacFactionChip(String faction) =>
      Key('almanac_faction_chip_$faction');
  static const almanacSortButton = Key('almanac_sort_button');
  static const almanacCountLabel = Key('almanac_count_label');
  static const almanacEmptyState = Key('almanac_empty_state');
  static const almanacList = Key('almanac_list');
  static Key almanacCandidateCard(String candidateId) =>
      Key('almanac_candidate_card_$candidateId');
  static const almanacDetailDialog = Key('almanac_detail_dialog');
  static const almanacDetailCloseButton = Key('almanac_detail_close_button');

  // Theme mode（テーマ設定）
  static const themeModeScreen = Key('theme_mode_screen');
  static const themeModeEntry = Key('theme_mode_entry');
  static Key themeModeOption(String storageKey) =>
      Key('theme_mode_option_$storageKey');

  // Turnout（投票率）
  static const turnoutScreen = Key('turnout_screen');
  static const turnoutTitle = Key('turnout_title');
  static const turnoutRateLabel = Key('turnout_rate_label');
  static const turnoutVoterSummary = Key('turnout_voter_summary');
  static const turnoutLevelLabel = Key('turnout_level_label');
  static const turnoutJobList = Key('turnout_job_list');
  static const turnoutCounterfactualCard = Key('turnout_counterfactual_card');
  static const turnoutVerdictLabel = Key('turnout_verdict_label');
  static const turnoutResultCard = Key('turnout_result_card');
  static const homeTurnoutButton = Key('home_turnout_button');
  static Key turnoutJobRow(String jobName) => Key('turnout_job_row_$jobName');
  static Key turnoutJobRate(String jobName) => Key('turnout_job_rate_$jobName');

  // Sound settings（サウンド設定）
  static const soundSettingsScreen = Key('sound_settings_screen');
  static const soundSettingsEntry = Key('sound_settings_entry');
  static const soundBgmSwitch = Key('sound_bgm_switch');
  static const soundSfxSwitch = Key('sound_sfx_switch');
  static const soundVolumeSlider = Key('sound_volume_slider');
  static const soundVolumeLabel = Key('sound_volume_label');
  static const soundSummaryLabel = Key('sound_summary_label');

  // Political groups（政党の可視化）
  static const politicalGroupsScreen = Key('political_groups_screen');
  static const politicalGroupsTitle = Key('political_groups_title');
  static const politicalGroupsSummaryCard = Key('political_groups_summary_card');
  static const politicalGroupsSearchField = Key('political_groups_search_field');
  static const politicalGroupsSearchClear = Key('political_groups_search_clear');
  static const politicalGroupsSortButton = Key('political_groups_sort_button');
  static const politicalGroupsCountLabel = Key('political_groups_count_label');
  static const politicalGroupsList = Key('political_groups_list');
  static const politicalGroupsSupportList = Key('political_groups_support_list');
  static const politicalGroupsEmptyState = Key('political_groups_empty_state');
  static const politicalGroupsDetailDialog = Key('political_groups_detail_dialog');
  static const politicalGroupsDetailCloseButton =
      Key('political_groups_detail_close_button');
  static const homePoliticalGroupsButton = Key('home_political_groups_button');
  static Key politicalGroupsMarker(String groupId) =>
      Key('political_groups_marker_$groupId');
  static Key politicalGroupsCard(String groupId) =>
      Key('political_groups_card_$groupId');
  static Key politicalGroupsQuadrantChip(String label) =>
      Key('political_groups_quadrant_chip_$label');
  static Key politicalGroupsSupportRow(String candidateId) =>
      Key('political_groups_support_row_$candidateId');

  // Election prediction（選挙結果の予想と答え合わせ）
  static const predictionScreen = Key('prediction_screen');
  static const predictionTitle = Key('prediction_title');
  static const predictionShareSlider = Key('prediction_share_slider');
  static const predictionShareLabel = Key('prediction_share_label');
  static const predictionSaveButton = Key('prediction_save_button');
  static const predictionOutcomeCard = Key('prediction_outcome_card');
  static const predictionWinnerHitBadge = Key('prediction_winner_hit_badge');
  static const predictionShareErrorLabel = Key('prediction_share_error_label');
  static const predictionScoreLabel = Key('prediction_score_label');
  static const predictionAccuracyLabel = Key('prediction_accuracy_label');
  static const homePredictionButton = Key('home_prediction_button');
  static Key predictionCandidateOption(String id) =>
      Key('prediction_candidate_option_$id');

  // Election recap（選挙の振り返りカード）
  static const recapTitle = Key('recap_title');
  static const recapCard = Key('recap_card');
  static const recapText = Key('recap_text');
  static const recapSelector = Key('recap_selector');
  static const recapCopyButton = Key('recap_copy_button');
  static const recapEmptyState = Key('recap_empty_state');
  static const recapSnackBar = Key('recap_snack_bar');
  static const archiveRecapButton = Key('archive_recap_button');

  // Glossary（政治用語辞典）
  static const glossaryScreen = Key('glossary_screen');
  static const glossaryTitle = Key('glossary_title');
  static const glossarySearchField = Key('glossary_search_field');
  static const glossarySearchClear = Key('glossary_search_clear');
  static const glossarySortButton = Key('glossary_sort_button');
  static const glossaryListCount = Key('glossary_list_count');
  static const glossaryEmptyState = Key('glossary_empty_state');
  static const glossaryCategoryFilterAll =
      Key('glossary_category_filter_all');
  static const homeGlossaryButton = Key('home_glossary_button');
  static Key glossaryCategoryChip(String label) =>
      Key('glossary_category_chip_$label');
  static Key glossaryTermTile(String id) =>
      Key('glossary_term_tile_$id');

  // Backup（データのエクスポート/バックアップ）
  static const backupScreen = Key('backup_screen');
  static const backupEntryCountLabel = Key('backup_entry_count_label');
  static const backupExportButton = Key('backup_export_button');
  static const backupExportOutput = Key('backup_export_output');
  static const backupCopyButton = Key('backup_copy_button');
  static const backupImportField = Key('backup_import_field');
  static const backupRestoreButton = Key('backup_restore_button');
  static const backupRestoreConfirmButton = Key('backup_restore_confirm_button');
  static const backupStatusLabel = Key('backup_status_label');
  static const backupErrorLabel = Key('backup_error_label');
  static const homeBackupButton = Key('home_backup_button');
  static Key backupCategoryRow(String name) => Key('backup_category_row_$name');

  // Manifesto tracker（公約実現度トラッカー）
  static const manifestoScreen = Key('manifesto_screen');
  static const manifestoTitle = Key('manifesto_title');
  static const manifestoSummary = Key('manifesto_summary');
  static const manifestoSearchField = Key('manifesto_search_field');
  static const manifestoSearchClear = Key('manifesto_search_clear');
  static const manifestoListCount = Key('manifesto_list_count');
  static const manifestoEmptyState = Key('manifesto_empty_state');
  static const homeManifestoButton = Key('home_manifesto_button');
  static Key manifestoRecordCard(String electionId) =>
      Key('manifesto_record_card_$electionId');
  static Key manifestoPledgeRow(String electionId, String lifeParamKey) =>
      Key('manifesto_pledge_row_${electionId}_$lifeParamKey');

  // Election reminder（選挙リマインダー・通知設定）
  static const reminderSettingsScreen = Key('reminder_settings_screen');
  static const reminderEnabledSwitch = Key('reminder_enabled_switch');
  static const reminderHourDropdown = Key('reminder_hour_dropdown');
  static const reminderMinuteDropdown = Key('reminder_minute_dropdown');
  static const reminderSaveButton = Key('reminder_save_button');
  static const reminderTestButton = Key('reminder_test_button');
  static const reminderStatusLabel = Key('reminder_status_label');
  static const homeReminderButton = Key('home_reminder_button');
  static Key reminderWeekdayChip(int weekday) =>
      Key('reminder_weekday_chip_$weekday');
  static Key reminderKindSwitch(String name) =>
      Key('reminder_kind_switch_$name');

  // Life param trend（生活パラメータの推移）
  static const lifeParamTrendScreen = Key('life_param_trend_screen');
  static const homeLifeParamTrendButton = Key('home_life_param_trend_button');
  static const lifeParamTrendEmpty = Key('life_param_trend_empty');
  static const lifeParamTrendLatest = Key('life_param_trend_latest');
  static Key lifeParamTrendKeyChip(String key) =>
      Key('life_param_trend_key_chip_$key');
  static Key lifeParamTrendBar(String electionId) =>
      Key('life_param_trend_bar_$electionId');
}
