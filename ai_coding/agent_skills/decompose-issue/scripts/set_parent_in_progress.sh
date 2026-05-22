#!/usr/bin/env bash
# set_parent_in_progress.sh
# 親issueのProjectステータスをIn Progressに更新する
#
# 使い方:
#   ./set_parent_in_progress.sh <PARENT_ITEM_ID>
#
# 必須環境変数:
#   PROJECT_ID              - プロジェクトのGlobal Node ID
#   STATUS_FIELD_ID         - StatusフィールドのID
#   IN_PROGRESS_OPTION_ID   - In ProgressステータスのオプションID
#
# 例:
#   export PROJECT_ID="PVT_xxx"
#   export STATUS_FIELD_ID="PVTSSF_xxx"
#   export IN_PROGRESS_OPTION_ID="opt_xxx"
#   ./set_parent_in_progress.sh "PVTI_yyy"

set -euo pipefail

PARENT_ITEM_ID="${1:?PARENT_ITEM_ID required (get from list_ai_agent_backlog.sh output)}"

: "${PROJECT_ID:?PROJECT_ID env var required}"
: "${STATUS_FIELD_ID:?STATUS_FIELD_ID env var required}"
: "${IN_PROGRESS_OPTION_ID:?IN_PROGRESS_OPTION_ID env var required}"

echo "🔄 Setting parent issue to In Progress..."
echo "   Item ID: ${PARENT_ITEM_ID}"

gh project item-edit \
  --id "$PARENT_ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --project-id "$PROJECT_ID" \
  --single-select-option-id "$IN_PROGRESS_OPTION_ID"

echo "✅ Parent issue status updated to In Progress"
