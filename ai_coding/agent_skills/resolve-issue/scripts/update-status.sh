#!/usr/bin/env bash
# update-status.sh
# イシューのステータスを "in progress" に更新し、作業完了後にクローズする
#
# 使い方 (ラベル方式):
#   ./update-status.sh OWNER/REPO ISSUE_NUMBER
#
# 使い方 (Projects v2 方式):
#   ./update-status.sh OWNER/REPO ISSUE_NUMBER PROJECT_ID ITEM_ID STATUS_FIELD_ID INPROGRESS_OPTION_ID [DONE_OPTION_ID]

set -euo pipefail

REPO="${1:-}"
ISSUE_NUMBER="${2:-}"
PROJECT_ID="${3:-}"
ITEM_ID="${4:-}"
STATUS_FIELD_ID="${5:-}"
INPROGRESS_OPTION_ID="${6:-}"
DONE_OPTION_ID="${7:-}"

if [[ -z "$REPO" || -z "$ISSUE_NUMBER" ]]; then
  echo "使い方: $0 OWNER/REPO ISSUE_NUMBER [PROJECT_ID ITEM_ID STATUS_FIELD_ID INPROGRESS_OPTION_ID [DONE_OPTION_ID]]" >&2
  exit 1
fi

# gh 認証確認
if ! gh auth status &>/dev/null; then
  echo "❌ GitHub CLI が未認証です。'gh auth login' を実行してください。" >&2
  exit 1
fi

echo "🚀 イシュー #$ISSUE_NUMBER の処理を開始します..."
echo ""

# ==============================
# Step 1: ステータスを "in progress" に更新
# ==============================

if [[ -n "$PROJECT_ID" && -n "$ITEM_ID" && -n "$STATUS_FIELD_ID" && -n "$INPROGRESS_OPTION_ID" ]]; then
  echo "🔄 [Projects v2] ステータスを 'In Progress' に更新中..."
  gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId:    $itemId
    fieldId:   $fieldId
    value: { singleSelectOptionId: $optionId }
  }) {
    projectV2Item { id }
  }
}' \
    -f projectId="$PROJECT_ID" \
    -f itemId="$ITEM_ID" \
    -f fieldId="$STATUS_FIELD_ID" \
    -f optionId="$INPROGRESS_OPTION_ID"
  echo "✅ Projects v2 ステータスを 'In Progress' に更新しました。"
else
  echo "🔄 [ラベル方式] ステータスを 'in-progress' に更新中..."
  # "ready" ラベルを外して "in-progress" ラベルを付ける
  gh issue edit "$ISSUE_NUMBER" --repo "$REPO" \
    --remove-label "ready" \
    --add-label "in-progress" 2>/dev/null || \
  gh issue edit "$ISSUE_NUMBER" --repo "$REPO" \
    --add-label "in-progress"
  echo "✅ ラベルを 'in-progress' に変更しました。"
fi

# 作業開始コメント
gh issue comment "$ISSUE_NUMBER" --repo "$REPO" \
  --body "🤖 **ai_agent**: このイシューの処理を開始します。
ステータスを **In Progress** に変更しました。

---
*自動処理中...*"

echo ""
echo "💬 作業開始コメントを投稿しました。"

# ==============================
# Step 2: イシュー内容を取得して表示
# ==============================

echo ""
echo "📄 イシュー詳細を取得中..."
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json title,body,comments \
  --jq '"## タイトル: \(.title)\n\n## 本文\n\(.body)\n\n## コメント数: \(.comments | length)"')

echo "$ISSUE_BODY"
echo ""
echo "⚠️  上記内容を確認し、必要な作業を実施してください。"
echo "   作業完了後、以下のコマンドでイシューをクローズしてください:"
echo ""
echo "   gh issue close $ISSUE_NUMBER --repo $REPO --comment '✅ 解決済み: <作業内容を記載>'"
echo ""

if [[ -n "$PROJECT_ID" && -n "$ITEM_ID" && -n "$STATUS_FIELD_ID" && -n "$DONE_OPTION_ID" ]]; then
  echo "   # Projects v2 のステータスも更新する場合:"
  echo "   gh api graphql -f query='mutation(...) { updateProjectV2ItemFieldValue(...) }' \\"
  echo "     -f projectId=\"$PROJECT_ID\" -f itemId=\"$ITEM_ID\" \\"
  echo "     -f fieldId=\"$STATUS_FIELD_ID\" -f optionId=\"$DONE_OPTION_ID\""
fi

echo ""
echo "🎯 処理対象: $REPO #$ISSUE_NUMBER"
