#!/usr/bin/env bash
# get-ready-issues.sh
# ai_agent ラベルかつ "Ready" ステータスのイシューを取得する
#
# 使い方:
#   chmod +x get-ready-issues.sh
#   ./get-ready-issues.sh OWNER/REPO [PROJECT_ID]
#
# PROJECT_ID を省略した場合はラベルのみでフィルタします（Projects v2 ステータスは無視）

set -euo pipefail

REPO="${1:-}"
PROJECT_ID="${2:-}"

if [[ -z "$REPO" ]]; then
  echo "使い方: $0 OWNER/REPO [PROJECT_ID]" >&2
  exit 1
fi

# gh 認証確認
if ! gh auth status &>/dev/null; then
  echo "❌ GitHub CLI が未認証です。'gh auth login' を実行してください。" >&2
  exit 1
fi

echo "📋 リポジトリ: $REPO"
echo "🔍 ai_agent ラベル + open イシューを取得中..."

if [[ -z "$PROJECT_ID" ]]; then
  # ラベルのみでフィルタ（Projects v2 なし）
  gh issue list \
    --repo "$REPO" \
    --label "ai_agent" \
    --state open \
    --json number,title,createdAt,url,labels \
    --jq '
      .[] |
      "  #\(.number) [\(.createdAt | split("T")[0])] \(.title)\n    \(.url)"
    '
else
  # Projects v2 を使ってステータス "Ready" でフィルタ
  echo "🗂️  プロジェクト: $PROJECT_ID"
  echo ""

  gh api graphql -f query='
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100) {
        nodes {
          id
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
          content {
            ... on Issue {
              number title url createdAt state
              labels(first: 10) { nodes { name } }
            }
          }
        }
      }
    }
  }
}' -f projectId="$PROJECT_ID" | \
  jq -r '
    .data.node.items.nodes[] |
    select(
      .content != null and
      .content.state == "OPEN" and
      (.content.labels.nodes[].name == "ai_agent") and
      (
        [.fieldValues.nodes[] |
          select(.field.name == "Status" and (.name | ascii_downcase) == "ready")
        ] | length > 0
      )
    ) |
    "itemId=\(.id)\n  #\(.content.number) [\(.content.createdAt | split("T")[0])] \(.content.title)\n  \(.content.url)\n"
  '
fi

echo ""
echo "✅ 取得完了。対象イシューの番号を確認して update-status.sh を実行してください。"
