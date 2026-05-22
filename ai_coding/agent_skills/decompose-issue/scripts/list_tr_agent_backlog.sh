#!/usr/bin/env bash
# list_ai_agent_backlog.sh
# ai_agentラベルがついたBacklogステータスのissueを一覧表示する
#
# 使い方:
#   ./list_ai_agent_backlog.sh <PROJECT_NUMBER> [OWNER] [REPO]
#
# 環境変数 (get_project_info.sh で取得):
#   PROJECT_ID       - プロジェクトのGlobal Node ID
#   STATUS_FIELD_ID  - StatusフィールドのID
#
# 例:
#   export PROJECT_ID="PVT_xxx"
#   export STATUS_FIELD_ID="PVTSSF_xxx"
#   ./list_ai_agent_backlog.sh 1 my-org my-org/my-repo

set -euo pipefail

PROJECT_NUMBER="${1:?Usage: $0 <PROJECT_NUMBER> [OWNER] [REPO]}"
OWNER="${2:-@me}"

echo "🔍 Fetching ai_agent Backlog issues from project #${PROJECT_NUMBER}..."
echo ""

# GraphQLでプロジェクトアイテムを取得（owner typeに応じて切り替え）
# まずuserとして試み、失敗したらorganizationとして再試行
fetch_items() {
  local owner_type="$1"
  gh api graphql -f query="
query(\$owner: String!, \$number: Int!) {
  ${owner_type}(login: \$owner) {
    projectV2(number: \$number) {
      id
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              url
              body
              labels(first: 10) {
                nodes { name }
              }
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field {
                  ... on ProjectV2SingleSelectField {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}" -f owner="$OWNER" -F number="$PROJECT_NUMBER" 2>/dev/null
}

# userとして試みる
RESULT=$(fetch_items "user" 2>/dev/null || true)

# エラーまたは空の場合はorganizationとして試みる
if [ -z "$RESULT" ] || echo "$RESULT" | jq -e '.errors' > /dev/null 2>&1; then
  echo "   (trying as organization...)"
  RESULT=$(fetch_items "organization")
fi

# ai_agentラベル + Backlogステータスで絞り込み
echo "$RESULT" | jq '
  [ .data | to_entries[].value.projectV2.items.nodes[]
    | select(
        .content != null and
        (.content.labels.nodes | map(.name) | contains(["ai_agent"])) and
        (.fieldValues.nodes[] | select(.field.name == "Status") | .name) == "Backlog"
      )
    | {
        itemId: .id,
        issueNumber: .content.number,
        title: .content.title,
        url: .content.url,
        bodyPreview: (.content.body | if . then .[0:200] else "(no body)" end)
      }
  ]
'
