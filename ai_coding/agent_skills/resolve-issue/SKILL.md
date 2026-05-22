---
name: agent-github-issue-solver
description: >
  GitHub CLIを使って特定リポジトリの "ai_agent" ラベルかつステータスが "ready" のイシューを
  一覧取得し、そのうち1件を "in progress" に更新してからイシューを解決するスキル。
  ユーザーが「ai_agentラベルのイシューを処理して」「GitHubのready状態のissueを解決して」
  「ai_agentのissueをin progressにしてから解決して」などと言ったとき、または
  GitHub issueの自動処理・エージェントワークフローを求めているときは必ずこのスキルを使うこと。
compatibility:
  tools:
    - bash_tool
  requirements:
    - GitHub CLI (gh) がインストール済みで認証済みであること
    - GitHub Projects v2 を使用している場合は適切なスコープのトークンが必要
---

# Agent GitHub Issue Solver

GitHub CLIを用いて、"ai_agent" ラベルかつ **ready** 状態のイシューを取得し、
1件を **in progress** に遷移させてから解決するワークフロー。

---

## ワークフロー概要

```
1. 事前確認      → gh コマンドが使えるか / 認証状態を確認
2. イシュー取得  → ai_agent ラベル + ready ステータスのイシューを列挙
3. 対象選択      → 取得した一覧からイシューを1件選択（最古 or ユーザー指定）
4. ステータス更新 → ready → in progress に変更
5. イシュー解決  → 内容を分析し、必要な作業を実施
6. PR作成      → プルリクエストを作成してイシューにリンク
```

---

## Step 0: 事前確認

```bash
# gh がインストールされているか確認
gh --version

# 認証状態の確認
gh auth status
```

失敗した場合はユーザーに `gh auth login` を実行するよう案内すること。

---

## Step 1: イシューの取得

### ラベルでフィルタしてイシューを取得

```bash
# OWNER/REPO は対象リポジトリに置き換える
gh issue list \
  --repo OWNER/REPO \
  --label "ai_agent" \
  --state open \
  --json number,title,labels,createdAt,assignees,projectItems \
  --limit 50
```

### GitHub Projects v2 のステータスで "ready" だけに絞る場合

Projects v2 のステータスはイシュー本体ではなくプロジェクトフィールドに保存される。
詳しい取得方法は `references/projects-v2.md` を参照。

簡易版（ラベルのみでフィルタ、ステータス確認は手動）:

```bash
gh issue list \
  --repo OWNER/REPO \
  --label "ai_agent" \
  --state open \
  --json number,title,body,createdAt,url
```

---

## Step 2: ステータスが "ready" のイシューを特定

Projects v2 を使う場合は GraphQL で取得する。`references/projects-v2.md` の
クエリを参照して `status == "Ready"` のアイテムだけを取り出すこと。

Projects を使わずラベルで代用している場合は:

```bash
# "ready" ラベルも併用しているケース
gh issue list \
  --repo OWNER/REPO \
  --label "ai_agent,ready" \
  --state open \
  --json number,title,body,createdAt,url
```

---

## Step 3: 対象イシューの選択

- 取得したリストをユーザーに提示する
- 特に指定がなければ **最も古い（createdAt が早い）** イシューを選択する
- ユーザーが番号を指定した場合はそれを優先する

---

## Step 4: ステータスを "in progress" に更新

### 方法A: GitHub Projects v2 フィールドを更新（推奨）

```bash
# プロジェクトアイテムのIDとフィールドIDが必要
# 取得方法は references/projects-v2.md を参照

gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $value }
  }) {
    projectV2Item { id }
  }
}
' -f projectId="PROJECT_ID" -f itemId="ITEM_ID" \
  -f fieldId="STATUS_FIELD_ID" -f value="IN_PROGRESS_OPTION_ID"
```

### 方法B: ラベルで管理している場合

```bash
ISSUE_NUMBER=<イシュー番号>
REPO="OWNER/REPO"

# "ready" ラベルを外して "in-progress" ラベルを追加
gh issue edit $ISSUE_NUMBER --repo $REPO \
  --remove-label "ready" \
  --add-label "in-progress"

# 作業開始のコメントを追加
gh issue comment $ISSUE_NUMBER --repo $REPO \
  --body "🤖 ai_agent: このイシューの処理を開始します。ステータスを **in progress** に変更しました。"
```

---

## Step 5: イシューの解決

1. イシューの本文・コメントを読んで必要な作業を把握する
2. 作業を実施する（コード修正、ドキュメント更新など）
3. 作業完了のコメントを投稿する

```bash
gh issue comment $ISSUE_NUMBER --repo $REPO \
  --body "✅ ai_agent: 以下の対応を完了しました。

## 実施内容
<作業内容をここに記載>

## 変更ファイル
<変更ファイルがあればここに列挙>

クローズします。"
```

---

## Step 6: PRの作成とイシューへのリンク

```bash
gh pr create --repo $REPO \
  --title "対応完了: $ISSUE_NUMBER" \
  --body "このPRはイシュー #$ISSUE_NUMBER に対応しています。" \
  --base main \
  --head feature/$ISSUE_NUMBER
```

```

Projects v2 のステータスも更新する場合は、Step 4 の GraphQL mutation を使って
ステータスを "in review" に変更すること。

---

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| `gh: command not found` | `brew install gh` / `winget install gh` を案内 |
| 認証エラー | `gh auth login` を実行するよう案内 |
| イシューが0件 | ユーザーに「対象イシューが見つかりませんでした」と報告 |
| GraphQL エラー | `references/projects-v2.md` の詳細クエリを参照 |
| 権限不足 | リポジトリへの write 権限 / プロジェクトへのアクセス権を確認 |

---

## 参考ファイル

- `references/projects-v2.md` — GitHub Projects v2 の GraphQL クエリ集
- `scripts/get-ready-issues.sh` — ready イシュー取得スクリプト
- `scripts/update-status.sh` — ステータス更新スクリプト
