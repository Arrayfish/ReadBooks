# GitHub Projects v2 — GraphQL クエリ集

GitHub Projects v2 のステータスはイシュー本体ではなくプロジェクトの
カスタムフィールドに保存されているため、GraphQL API を使う必要がある。

---

## 目次

1. プロジェクト一覧の取得
2. プロジェクト内のイシュー + ステータスの取得
3. "ready" イシューだけを絞り込む
4. ステータスを "in progress" に更新する
5. IDを特定するためのクエリ

---

## 1. プロジェクト一覧の取得

```bash
# オーナー（ユーザー）のプロジェクト一覧
gh api graphql -f query='
query($login: String!) {
  user(login: $login) {
    projectsV2(first: 20) {
      nodes { id title number }
    }
  }
}
' -f login="GITHUB_USERNAME"

# オーガニゼーションのプロジェクト一覧
gh api graphql -f query='
query($org: String!) {
  organization(login: $org) {
    projectsV2(first: 20) {
      nodes { id title number }
    }
  }
}
' -f org="ORG_NAME"
```

---

## 2. プロジェクト内のイシュー + ステータスの取得

```bash
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
                name          # ステータス名 (例: "Ready", "In Progress", "Done")
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
          content {
            ... on Issue {
              number
              title
              url
              labels(first: 10) { nodes { name } }
              createdAt
              state
            }
          }
        }
      }
    }
  }
}
' -f projectId="PROJECT_ID"
```

---

## 3. "ready" イシューの絞り込み

上記クエリの結果を jq でフィルタする:

```bash
gh api graphql -f query='...(上記クエリ)...' -f projectId="PROJECT_ID" | \
jq '
  .data.node.items.nodes[] |
  select(
    .content.labels.nodes[].name == "ai_agent" and
    (.fieldValues.nodes[] | select(.field.name == "Status") | .name) == "Ready"
  ) |
  {
    itemId: .id,
    issueNumber: .content.number,
    title: .content.title,
    url: .content.url,
    createdAt: .content.createdAt
  }
'
```

---

## 4. ステータスを "in progress" に更新

### 4-1. Status フィールドの ID と選択肢IDを取得

```bash
gh api graphql -f query='
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options { id name }
          }
        }
      }
    }
  }
}
' -f projectId="PROJECT_ID"
```

出力例:
```json
{
  "id": "FIELD_ID_XXXX",
  "name": "Status",
  "options": [
    { "id": "OPT_READY_ID",       "name": "Ready" },
    { "id": "OPT_INPROGRESS_ID",  "name": "In Progress" },
    { "id": "OPT_DONE_ID",        "name": "Done" }
  ]
}
```

### 4-2. ステータスを更新するミューテーション

```bash
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
}
' \
  -f projectId="PROJECT_ID" \
  -f itemId="ITEM_ID" \
  -f fieldId="STATUS_FIELD_ID" \
  -f optionId="OPT_INPROGRESS_ID"
```

---

## 5. プロジェクトID をリポジトリから特定する

```bash
# リポジトリに紐づいているプロジェクトを確認
gh api graphql -f query='
query($owner: String!, $repo: String!) {
  repository(owner: $owner, name: $repo) {
    projectsV2(first: 10) {
      nodes { id title number }
    }
  }
}
' -f owner="OWNER" -f repo="REPO"
```

---

## よく使う変数のまとめ

| 変数名 | 説明 | 取得方法 |
|--------|------|----------|
| `PROJECT_ID` | プロジェクトのグローバルID | セクション1 or 5 |
| `ITEM_ID` | プロジェクト内のアイテムID（イシューではない） | セクション2 |
| `STATUS_FIELD_ID` | Statusフィールドのグローバルフィールドid | セクション4-1 |
| `OPT_INPROGRESS_ID` | "In Progress" 選択肢のID | セクション4-1 |
