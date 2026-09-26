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
}
