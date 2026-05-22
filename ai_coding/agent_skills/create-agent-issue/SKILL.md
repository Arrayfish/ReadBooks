---
name: agent-issue
description: Creates GitHub Issues for coding agents from user requirements without Backlog. Manual invocation only. For Backlog tickets, use bl-issue instead.
disable-model-invocation: true
---

# Agent Issue（Backlog なし）

**手動利用専用。** `@agent-issue` で明示したときだけ従う。

Backlog 課題・Backlog MCP は**使わない**。要件はユーザーの説明、貼り付け仕様、既存ドキュメント、GitHub Issue/PR、コード調査から組み立てる。

Backlog キー（`PROJECT-1234`）や Backlog URL が来たら、作業を止め `@bl-issue` への切り替えを案内する。

## 前提確認

1. **出力先**: GitHub Issue（`gh issue create` または GitHub UI）
2. **入力**: 会話・Markdown・設計メモ等（Backlog 以外）
3. **リポジトリ**: [reference.md](reference.md) のテンプレート・ラベル方針を適用

## ワークフロー

```
Task Progress:
- [ ] 要件を収集（ユーザー入力 / リポジトリ調査）
- [ ] 不足情報をユーザーに確認
- [ ] Issue 本文ドラフトを提示して承認
- [ ] GitHub Issue を作成
- [ ] 作成結果（URL・番号）を報告
```

### Step 1: 要件の収集

| 入力 | 次のアクション |
|------|----------------|
| 口頭・チャットでの要件 | Step 2 へ。曖昧な点は質問 |
| 仕様・設計の貼り付け | 出典を「参照」に記載して Step 2 へ |
| バグ報告 | 再現手順・期待結果・実結果を必ず聞く |
| Backlog キー / URL | **中断** → `@bl-issue` を案内 |

必要ならリポジトリを読み、関連ファイル・既存パターンを「実装タスク」に具体化する（推測は「想定」として明示）。

### Step 2: 本文の組み立て

[reference.md](reference.md) のテンプレートに従う。

- **自己完結** / **検証可能** / **スコープ明確** / **最小変更**
- **出典**: ユーザー提供の仕様・会話・ドキュメント URL のみ

タイトル: `{type}: {短い要約}`（`feat` / `fix` / `refactor` 等）

### Step 3: 作成

1. タイトル・本文・ラベルを提示
2. 承認後:

```bash
gh issue create \
  --title "タイトル" \
  --body-file /tmp/agent-issue-body.md \
  --label "ラベル"
```

3. Issue 番号・URL を返す

## 品質チェック

- [ ] 受け入れ条件あり
- [ ] 実装タスクが具体化されている
- [ ] 機密・Backlog キー/URL を含めていない

## 追加リソース

- [reference.md](reference.md)
- Backlog 課題: `../bl-issue/SKILL.md`
