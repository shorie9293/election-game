import 'package:flutter/material.dart';

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

  // Ending
  static const endingConcernGrowth = Key('ending_concern_growth');

  // Tutorial overlay
  static const tutorialOverlay = Key('tutorial_overlay');
  static const tutorialNextButton = Key('tutorial_next_button');
  static const tutorialSkipButton = Key('tutorial_skip_button');
  static const tutorialText = Key('tutorial_text');
}
