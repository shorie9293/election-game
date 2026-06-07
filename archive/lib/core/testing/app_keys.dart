import 'package:flutter/material.dart';

/// 全画面・全Widgetの試験用Keyを一元管理。
/// 重複禁止。命名規則: <画面名>_<要素名>
class AppKeys {
  AppKeys._();

  // Title
  static const titleStart = Key('title_start');
  static const titleContinue = Key('title_continue');

  // Citizen creation
  static const citizenNameInput = Key('citizen_name_input');
  static const citizenJobSelector = Key('citizen_job_selector');
  static const citizenCreateButton = Key('citizen_create_button');

  // Home
  static const homeTitle = Key('home_title');
  static const homeLifeParams = Key('home_life_params');
  static const homeElectionButton = Key('home_election_button');
  static const homeSocietyMood = Key('home_society_mood');

  // Election announcement (newspaper)
  static const newspaperTitle = Key('newspaper_title');
  static const newspaperCandidateList = Key('newspaper_candidate_list');
  static const newspaperProceedButton = Key('newspaper_proceed_button');

  // Candidate detail
  static const candidateDetailTitle = Key('candidate_detail_title');
  static const candidatePolicies = Key('candidate_policies');
  static const candidateSupportGroup = Key('candidate_support_group');

  // Vote
  static const voteTitle = Key('vote_title');
  static const voteCandidateList = Key('vote_candidate_list');
  static const voteConfirmButton = Key('vote_confirm_button');

  // Election result (newspaper)
  static const resultTitle = Key('result_title');
  static const resultWinner = Key('result_winner');
  static const resultLifeImpact = Key('result_life_impact');
  static const resultContinueButton = Key('result_continue_button');

  // Shared
  static const backButton = Key('back_button');
}
