---
name: decompose-issue
description: >
  GitHub CLIを使って、ai_agentラベルが付与されBacklogステータスのissueを調査し、
  Sonnet 4.6が一回の実行で処理できる粒度の子issueに分割して、Readyステータスで
  子issueとして登録し、親issueをIn Progressに更新するスキル。
  「ai_agentのissueを分解して」「ai_agentのbacklogを処理して」「issueを子issueに分割して」
  「github issueを分解してサブタスクを作って」のような依頼で必ず使うこと。
  GitHub ProjectsのV2とGitHub CLIを組み合わせて使用する。
---

# ai_agent Issue Decomposer スキル

GitHub CLIを使ってai_agentラベルのBacklog issueを調査し、Sonnet 4.6が一回で処理できる粒度に分解して子issueを登録するスキル。

## 前提条件

- `gh` CLI がインストール済みで認証済みであること (`gh auth status` で確認)
- プロジェクトスコープが必要: `gh auth refresh -s project`
- 対象リポジトリとGitHub Projectsへのアクセス権があること

## ワークフロー概要

```
1. リポジトリ・プロジェクト情報の取得
2. ai_agentラベル + Backlogステータスのissueを一覧取得
3. issueを一つ選択して詳細を調査
4. Sonnet 4.6が一回で処理できる粒度に分解
5. 子issueをReadyステータスで登録
6. 親issueをIn Progressに更新
```

---

## STEP 1: 認証・リポジトリ確認

```bash
# 認証確認
gh auth status

# プロジェクトスコープ追加（必要な場合）
gh auth refresh -s project

# カレントディレクトリのリポジトリ確認（または -R OWNER/REPO を指定）
gh repo view --json nameWithOwner
```

---

## STEP 2: ai_agentラベル + Backlogステータスのissue一覧取得

GitHub ProjectsのステータスはProject V2のフィールドで管理されているため、GraphQL APIで取得する。

### 2-1. Projectの一覧取得

```bash
# オーナーのプロジェクト一覧（@meまたはorg名）
gh project list --owner "@me" --format json | jq '.projects[] | {number, title, id}'

# または組織の場合
gh project list --owner "ORG_NAME" --format json | jq '.projects[] | {number, title, id}'
```

### 2-2. ProjectのStatusフィールドIDとオプションIDを取得

```bash
PROJECT_NUMBER=<プロジェクト番号>
OWNER="@me"  # または org名

gh project field-list $PROJECT_NUMBER --owner "$OWNER" --format json \
  | jq '.fields[] | select(.name == "Status") | {id, options: .options}'
```

出力例:
```json
{
  "id": "PVTSSF_xxx",
  "options": [
    {"id": "opt_backlog_id", "name": "Backlog"},
    {"id": "opt_ready_id", "name": "Ready"},
    {"id": "opt_inprogress_id", "name": "In Progress"}
  ]
}
```

### 2-3. Backlogステータスのissue一覧取得

```bash
# ai_agentラベルのissueをまず取得
gh issue list --label "ai_agent" --state open --json number,title,body,url,labels \
  | jq '.[] | {number, title, url}'
```

次に、ProjectのアイテムからStatusがBacklogのものを絞り込む（GraphQL使用）:

```bash
# GraphQLでBacklogアイテムを取得
gh api graphql -f query='
query($owner: String!, $number: Int!) {
  user(login: $owner) {
    projectV2(number: $number) {
      items(first: 50) {
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              url
              labels(first: 10) {
                nodes { name }
              }
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
      }
    }
  }
}' -f owner="OWNER" -F number=PROJECT_NUMBER \
| jq '
  .data.user.projectV2.items.nodes[]
  | select(
      (.content.labels.nodes[].name == "ai_agent") and
      (.fieldValues.nodes[] | select(.field.name == "Status") | .name) == "Backlog"
    )
  | {
      itemId: .id,
      issueNumber: .content.number,
      title: .content.title,
      url: .content.url
    }
'
```

> **注意**: organizationの場合は `user(login:)` を `organization(login:)` に変更する。

---

## STEP 3: issueの詳細調査

一覧から処理するissueを1つ選ぶ（最初のBacklog issueを選択するか、ユーザーに確認する）。

```bash
ISSUE_NUMBER=<選択したissue番号>
REPO="OWNER/REPO"

# issue本文・コメント・関連情報を取得
gh issue view $ISSUE_NUMBER -R "$REPO" --json \
  number,title,body,labels,comments,assignees,milestone
```

issueの内容を読んで以下を把握する:
- **目的**: このissueが何を達成しようとしているか
- **スコープ**: 技術的な作業範囲
- **依存関係**: 他のissueや前提条件

---

## STEP 4: Sonnet 4.6が一回で処理できる粒度への分解

### 分解の基準

Sonnet 4.6が**一回の実行**で処理できる子issueの条件:

| 条件 | 説明 |
|------|------|
| **単一の成果物** | 1つのファイル編集、1つのスクリプト、1つのテスト群など |
| **明確なゴール** | 完了条件が「〜が動く」「〜を返す」など客観的に判定できる |
| **30分以内の作業** | 人間換算で30分〜1時間程度の作業量 |
| **独立性** | 他の子issueに依存せず単独で着手・完了できる |
| **コンテキストが自己完結** | issueの説明だけで作業開始できる |

### 分解パターン

```
親issue: 「認証システムをOAuthに移行する」
↓ 子issueに分解:
  1. OAuthプロバイダーの設定ファイルを作成する
  2. ログインエンドポイントをOAuth対応に書き換える
  3. セッション管理ロジックをOAuth tokenに対応させる
  4. 既存の認証テストをOAuth対応に更新する
  5. README認証セクションを更新する
```

### 分解時の注意点

- **過度な細分化を避ける**: 「変数名を変える」レベルは小さすぎる
- **過度な統合を避ける**: 「全部書き直す」は大きすぎる
- **順序を明示**: 依存する子issueがある場合はタイトルに「[1/N]」を付ける
- **親issueの文脈を各子issueに含める**: 子issue単体で理解できるよう背景を書く

---

## STEP 5: 子issueをReadyステータスで登録

### 5-1. 子issueをGitHubに作成

```bash
REPO="OWNER/REPO"
PARENT_ISSUE_NUMBER=<親のissue番号>

# 子issue作成（ループで各サブタスクを登録）
CHILD_ISSUE_NUMBER=$(gh issue create \
  --repo "$REPO" \
  --title "[子issue] タイトル" \
  --body "## 背景
親issue: #${PARENT_ISSUE_NUMBER}

## 目的
（何を達成するか）

## 作業内容
（具体的なタスク）

## 完了条件
（どうなったら完了か）" \
  --label "ai_agent" \
  --json number --jq '.number')

echo "Created child issue: #$CHILD_ISSUE_NUMBER"
```

### 5-2. 子issueをProjectに追加してReadyステータスを設定

```bash
PROJECT_NUMBER=<プロジェクト番号>
OWNER="OWNER_NAME"
REPO="OWNER/REPO"
STATUS_FIELD_ID="PVTSSF_xxx"       # STEP 2-2で取得したフィールドID
READY_OPTION_ID="opt_ready_id"      # STEP 2-2で取得したReadyオプションID

# issueのURLを取得
CHILD_ISSUE_URL=$(gh issue view $CHILD_ISSUE_NUMBER -R "$REPO" --json url --jq '.url')

# Projectにissueを追加してアイテムIDを取得
ITEM_ID=$(gh project item-add $PROJECT_NUMBER \
  --owner "$OWNER" \
  --url "$CHILD_ISSUE_URL" \
  --format json --jq '.id')

echo "Project item ID: $ITEM_ID"

# ステータスをReadyに設定
PROJECT_ID=$(gh project list --owner "$OWNER" --format json \
  | jq -r --argjson num $PROJECT_NUMBER '.projects[] | select(.number == $num) | .id')

gh project item-edit \
  --id "$ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --project-id "$PROJECT_ID" \
  --single-select-option-id "$READY_OPTION_ID"
```

### 5-3. 子issueの親issueへのリンク（Sub-issues API）

GitHubのSub-issues機能（GraphQL）を使って親子関係を設定する:

```bash
# 子issueのnode IDを取得
CHILD_NODE_ID=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) { id }
  }
}' -f owner="OWNER" -f repo="REPO" -F number=$CHILD_ISSUE_NUMBER \
  | jq -r '.data.repository.issue.id')

# 親issueのnode IDを取得
PARENT_NODE_ID=$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) { id }
  }
}' -f owner="OWNER" -f repo="REPO" -F number=$PARENT_ISSUE_NUMBER \
  | jq -r '.data.repository.issue.id')

# 子issueとして追加
gh api graphql -f query='
mutation($parentId: ID!, $childId: ID!) {
  addSubIssue(input: {issueId: $parentId, subIssueId: $childId}) {
    issue { number title }
    subIssue { number title }
  }
}' -f parentId="$PARENT_NODE_ID" -f childId="$CHILD_NODE_ID"
```

> **注意**: Sub-issues APIはGitHub Enterpriseまたは一部プランで利用可能。利用できない場合は親issueのbodyに `- [ ] #子issue番号` 形式で手動リンクする（下記参照）。

**Sub-issues APIが使えない場合の代替手段**（本文にチェックリスト追記）:

```bash
# 親issueの現在のbodyを取得
CURRENT_BODY=$(gh issue view $PARENT_ISSUE_NUMBER -R "$REPO" --json body --jq '.body')

# 子issueのチェックリストを末尾に追記
NEW_BODY="${CURRENT_BODY}

## Sub-tasks
- [ ] #${CHILD_ISSUE_NUMBER} タイトル"

gh issue edit $PARENT_ISSUE_NUMBER -R "$REPO" --body "$NEW_BODY"
```

---

## STEP 6: 親issueをIn Progressに更新

```bash
PARENT_ITEM_ID=<親issueのProjectアイテムID>  # STEP 2-3で取得済み
IN_PROGRESS_OPTION_ID="opt_inprogress_id"    # STEP 2-2で取得済み

gh project item-edit \
  --id "$PARENT_ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --project-id "$PROJECT_ID" \
  --single-select-option-id "$IN_PROGRESS_OPTION_ID"

echo "✅ 親issue #${PARENT_ISSUE_NUMBER} のステータスをIn Progressに更新しました"
```

---

## 実行チェックリスト

スキル使用時に以下の順番で実行すること:

- [ ] `gh auth status` で認証確認
- [ ] ProjectのID・フィールドID・オプションIDを取得・保存
- [ ] ai_agent + Backlogのissueを一覧取得
- [ ] 対象issueを1つ選択（複数ある場合はユーザーに確認）
- [ ] issueの詳細を`gh issue view`で取得・分析
- [ ] 分解案を作成してユーザーに確認（任意）
- [ ] 各子issueをGitHubに作成
- [ ] 各子issueをProjectに追加してReadyステータスを設定
- [ ] 子issueと親issueをリンク（Sub-issues APIまたはチェックリスト）
- [ ] 親issueをIn Progressに更新
- [ ] 完了報告（作成した子issueの一覧を表示）

---

## トラブルシューティング

### "Must have push access" エラー
→ リポジトリへの書き込み権限が必要。権限を確認してください。

### Project statusが更新されない
→ `gh auth refresh -s project` でprojectスコープを追加する。

### Sub-issues mutationが失敗する
→ GitHubプランがSub-issuesをサポートしていない可能性。代替手段（チェックリスト）を使う。

### GraphQLでorganizationが見つからない
→ `user(login:)` を `organization(login:)` に変更する。

### StatusオプションIDが不明
→ `gh project field-list` の出力をそのまま表示してユーザーに確認を求める。
