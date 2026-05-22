#!/usr/bin/env bash
# get_project_info.sh
# GitHub ProjectのID、StatusフィールドID、各ステータスのオプションIDを取得する
#
# 使い方:
#   ./get_project_info.sh <PROJECT_NUMBER> [OWNER]
#
# 引数:
#   PROJECT_NUMBER  - GitHubプロジェクト番号 (例: 1)
#   OWNER           - GitHubユーザー名または組織名 (省略時は "@me")
#
# 出力: JSON形式でプロジェクト情報を表示
#
# 例:
#   ./get_project_info.sh 1
#   ./get_project_info.sh 3 my-org

set -euo pipefail

PROJECT_NUMBER="${1:?Usage: $0 <PROJECT_NUMBER> [OWNER]}"
OWNER="${2:-@me}"

echo "📋 Fetching project info for project #${PROJECT_NUMBER} (owner: ${OWNER})..."
echo ""

# プロジェクト一覧からIDを取得
PROJECT_INFO=$(gh project list --owner "$OWNER" --format json \
  | jq --argjson num "$PROJECT_NUMBER" \
    '.projects[] | select(.number == $num) | {id, title, number}')

if [ -z "$PROJECT_INFO" ]; then
  echo "❌ Project #${PROJECT_NUMBER} not found for owner '${OWNER}'"
  echo "Available projects:"
  gh project list --owner "$OWNER" --format json | jq '.projects[] | {number, title}'
  exit 1
fi

PROJECT_ID=$(echo "$PROJECT_INFO" | jq -r '.id')
PROJECT_TITLE=$(echo "$PROJECT_INFO" | jq -r '.title')

echo "✅ Project: ${PROJECT_TITLE}"
echo "   ID: ${PROJECT_ID}"
echo ""

# StatusフィールドとオプションIDを取得
echo "📊 Fetching Status field options..."
STATUS_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json \
  | jq '.fields[] | select(.name == "Status")')

if [ -z "$STATUS_FIELD" ]; then
  echo "❌ No 'Status' field found. Available fields:"
  gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json \
    | jq '.fields[] | {name, id}'
  exit 1
fi

STATUS_FIELD_ID=$(echo "$STATUS_FIELD" | jq -r '.id')
echo "✅ Status field ID: ${STATUS_FIELD_ID}"
echo ""
echo "📌 Status options:"
echo "$STATUS_FIELD" | jq '.options[] | {name, id}'

echo ""
echo "═══════════════════════════════════════"
echo "Export these variables for use in other scripts:"
echo "═══════════════════════════════════════"
echo "export PROJECT_ID=\"${PROJECT_ID}\""
echo "export STATUS_FIELD_ID=\"${STATUS_FIELD_ID}\""

# Backlog / Ready / In Progress のIDを自動検出
BACKLOG_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name | test("(?i)backlog")) | .id // empty')
READY_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name | test("(?i)ready")) | .id // empty')
IN_PROGRESS_ID=$(echo "$STATUS_FIELD" | jq -r '.options[] | select(.name | test("(?i)in.?progress")) | .id // empty')

[ -n "$BACKLOG_ID" ]      && echo "export BACKLOG_OPTION_ID=\"${BACKLOG_ID}\""
[ -n "$READY_ID" ]        && echo "export READY_OPTION_ID=\"${READY_ID}\""
[ -n "$IN_PROGRESS_ID" ]  && echo "export IN_PROGRESS_OPTION_ID=\"${IN_PROGRESS_ID}\""
