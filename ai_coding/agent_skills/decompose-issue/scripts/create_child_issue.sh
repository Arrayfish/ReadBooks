#!/usr/bin/env bash
# create_child_issue.sh
# 子issueをGitHubに作成し、Projectに追加してReadyステータスを設定する
#
# 使い方:
#   ./create_child_issue.sh <REPO> <PARENT_NUMBER> <TITLE> <BODY_FILE>
#
# 必須環境変数:
#   PROJECT_NUMBER      - GitHubプロジェクト番号
#   OWNER               - GitHubオーナー（ユーザーまたはorg）
#   PROJECT_ID          - プロジェクトのGlobal Node ID
#   STATUS_FIELD_ID     - StatusフィールドのID
#   READY_OPTION_ID     - ReadyステータスのオプションID
#
# オプション環境変数:
#   EXTRA_LABELS        - 追加するラベル（カンマ区切り）
#
# 例:
#   export PROJECT_NUMBER=1
#   export OWNER="my-org"
#   export PROJECT_ID="PVT_xxx"
#   export STATUS_FIELD_ID="PVTSSF_xxx"
#   export READY_OPTION_ID="opt_xxx"
#   ./create_child_issue.sh my-org/my-repo 42 "子タスク: APIを実装する" /tmp/body.md

set -euo pipefail

REPO="${1:?REPO required}"
PARENT_NUMBER="${2:?PARENT_NUMBER required}"
TITLE="${3:?TITLE required}"
BODY_FILE="${4:?BODY_FILE required (path to markdown file)}"

: "${PROJECT_NUMBER:?PROJECT_NUMBER env var required}"
: "${OWNER:?OWNER env var required}"
: "${PROJECT_ID:?PROJECT_ID env var required}"
: "${STATUS_FIELD_ID:?STATUS_FIELD_ID env var required}"
: "${READY_OPTION_ID:?READY_OPTION_ID env var required}"

LABELS="ai_agent${EXTRA_LABELS:+,$EXTRA_LABELS}"

echo "📝 Creating child issue: ${TITLE}"
echo "   Parent: #${PARENT_NUMBER} | Repo: ${REPO}"
echo ""

# 1. issueを作成
CHILD_NUMBER=$(gh issue create \
  --repo "$REPO" \
  --title "$TITLE" \
  --body-file "$BODY_FILE" \
  --label "$LABELS" \
  --json number --jq '.number')

CHILD_URL=$(gh issue view "$CHILD_NUMBER" -R "$REPO" --json url --jq '.url')
echo "✅ Created issue #${CHILD_NUMBER}: ${CHILD_URL}"

# 2. Projectにissueを追加
echo "   Adding to project #${PROJECT_NUMBER}..."
ITEM_ID=$(gh project item-add "$PROJECT_NUMBER" \
  --owner "$OWNER" \
  --url "$CHILD_URL" \
  --format json --jq '.id')
echo "   Project item ID: ${ITEM_ID}"

# 3. ステータスをReadyに設定
echo "   Setting status to Ready..."
gh project item-edit \
  --id "$ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --project-id "$PROJECT_ID" \
  --single-select-option-id "$READY_OPTION_ID" \
  > /dev/null

echo "✅ Status set to Ready"

# 4. 子issueと親issueをSub-issues APIでリンク（失敗時はスキップ）
echo "   Linking as sub-issue of #${PARENT_NUMBER}..."

CHILD_NODE_ID=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) { issue(number: $number) { id } }
}' \
  -f owner="${REPO%%/*}" -f repo="${REPO##*/}" -F number="$CHILD_NUMBER" \
  | jq -r '.data.repository.issue.id')

PARENT_NODE_ID=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) { issue(number: $number) { id } }
}' \
  -f owner="${REPO%%/*}" -f repo="${REPO##*/}" -F number="$PARENT_NUMBER" \
  | jq -r '.data.repository.issue.id')

SUB_ISSUE_RESULT=$(gh api graphql -f query='
mutation($parentId: ID!, $childId: ID!) {
  addSubIssue(input: {issueId: $parentId, subIssueId: $childId}) {
    issue { number }
    subIssue { number }
  }
}' -f parentId="$PARENT_NODE_ID" -f childId="$CHILD_NODE_ID" 2>&1 || true)

if echo "$SUB_ISSUE_RESULT" | jq -e '.data.addSubIssue' > /dev/null 2>&1; then
  echo "✅ Linked as sub-issue via GitHub Sub-issues API"
else
  echo "⚠️  Sub-issues API unavailable, linking via checklist in parent issue body"
  # フォールバック: 親issueのbodyにチェックリストを追記
  CURRENT_BODY=$(gh issue view "$PARENT_NUMBER" -R "$REPO" --json body --jq '.body')
  
  # 既存のSub-tasksセクションがあるか確認
  if echo "$CURRENT_BODY" | grep -q "## Sub-tasks"; then
    NEW_BODY=$(echo "$CURRENT_BODY" | sed "s|## Sub-tasks|## Sub-tasks\n- [ ] #${CHILD_NUMBER} ${TITLE}|")
  else
    NEW_BODY="${CURRENT_BODY}

## Sub-tasks
- [ ] #${CHILD_NUMBER} ${TITLE}"
  fi
  
  gh issue edit "$PARENT_NUMBER" -R "$REPO" --body "$NEW_BODY" > /dev/null
  echo "✅ Added to parent issue checklist"
fi

echo ""
echo "✨ Child issue #${CHILD_NUMBER} created successfully with Ready status"
echo "$CHILD_NUMBER"  # 最後にissue番号を出力（呼び出し元でキャプチャ可能）
