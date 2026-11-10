import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/about/domain/about_info.dart';

void main() {
  test('kAboutInfo.version は pubspec.yaml の version と一致する', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml に version 行がない');
    expect(kAboutInfo.version, match!.group(1));
  });

  test('リリース版数は 1.0.54+61（復元内訳プレビュー同梱版）', () {
    expect(kAboutInfo.version, '1.0.54+61');
  });
}
