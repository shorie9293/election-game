#!/bin/bash
# ⛩️ Pre-deploy check — デプロイ前に CI 同等の全チェックをローカル実行
# election-game 専用：deploy.yml と同じ「pub get → analyze → 全量 test」を再現する
# 八百万の掟：デプロイ前には必ずこのスクリプトを通せ
#
# 注記：ビルド（flutter build appbundle）と Play 配信（fastlane / keystore）は
#       CI 側（.github/workflows/deploy.yml）でのみ実行する。
#       署名鍵・Play サービスアカウントはローカルに置かないため、ここでは再現しない。
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

export PATH="/tmp/flutter/bin:$PATH"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⛩️  Pre-deploy check: election-game"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- Step 1/3: flutter pub get ---
echo ""
echo "[1/3] 📦 flutter pub get..."
flutter pub get
echo "✅ pub get OK"

# --- Step 2/3: flutter analyze ---
# --no-fatal-infos: info は非致命（このリポジトリは info を許容し warning 以上で落とす）
echo ""
echo "[2/3] 🔍 flutter analyze --no-fatal-infos..."
flutter analyze --no-fatal-infos
echo "✅ analyze OK (no warnings or errors)"

# --- Step 3/3: 全量 test ---
# TZ=UTC は必須：CI（ubuntu-latest）は UTC で走る。JST 前提の時限爆弾をローカルで検出するため。
echo ""
echo "[3/3] 🧪 flutter test (TZ=UTC, full suite)..."
TZ=UTC flutter test --no-pub --reporter compact test
echo "✅ test: full suite passed"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Pre-deploy check PASSED — safe to deploy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "※ ビルド（appbundle）と Play 配信（fastlane）は CI 側で実行される"
