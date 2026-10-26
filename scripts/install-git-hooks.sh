#!/bin/bash
# ⛩️ Git hooks 設置 — scripts/ 配下の正本を .git/hooks/ へ配る
# .git/hooks は追跡外ゆえ、clone 直後は必ずこれを一度実行せよ。
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

cp scripts/pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push

echo "✅ installed: .git/hooks/pre-push (from scripts/pre-push)"
