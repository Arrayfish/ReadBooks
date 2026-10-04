# Codexの利用量を抑えるサブエージェント運用

Codexの汎用性を保ちながら利用量を抑えるには、モデルの選択と、サブエージェントを使う条件の両方を整える必要がある。小さな作業は親エージェントが直接処理し、調査・実装・レビューの委譲が有効な場合にだけサブエージェントを利用する。

本書では、次の設定を出発点とする。

- サブエージェントの既定モデル：`gpt-6-luna`
- サブエージェントの推論強度：`medium`
- 同時実行数の設定値：`2`
- エージェントの役割：Explorer、Worker、Reviewer

サブエージェントの起動にも推論や情報の受け渡しが発生するため、委譲すれば必ず利用量が減るわけではない。モデルを軽量化することに加え、不要な起動、重複調査、過剰な検証を避けることが重要となる。

## 1. 基本設定

`~/.codex/config.toml`に、サブエージェントの既定値と各役割の設定ファイルを指定する。

```toml
[agents]
enabled = true

# sub-agentは原則として低コストモデル
default_subagent_model = "gpt-6-luna"

# lowだと実装で弱すぎる場合があるので、汎用設定ではmedium
default_subagent_reasoning_effort = "medium"

# 無制限に並列化させない
max_concurrent_threads_per_session = 2

[agents.explorer]
description = """
Read-only repository investigation.

Use when the relevant implementation, dependencies,
existing patterns, or impact of a change are unclear.

Prefer targeted investigation.
Do not use for trivial changes where the relevant code
is already obvious.
"""
config_file = "agents/explorer.toml"

[agents.worker]
description = """
Implementation agent for clearly scoped coding work.

Use when the required behavior and relevant code area
are already sufficiently understood.

Prefer small, focused changes.
Do not use multiple workers on overlapping code.
"""
config_file = "agents/worker.toml"

[agents.reviewer]
description = """
Independent review agent for non-trivial completed changes.

Use when an independent correctness or regression review
is likely to provide meaningful value.

Do not invoke for trivial or mechanical changes.
"""
config_file = "agents/reviewer.toml"
```

`max_concurrent_threads_per_session`を明示し、同時実行数を制限する。役割は3種類用意するが、作業の内容に応じて必要な役割だけを選ぶ。

| 役割 | 設定ファイル | 主な担当 |
| --- | --- | --- |
| Explorer | `~/.codex/agents/explorer.toml` | 関連コードや依存関係の調査 |
| Worker | `~/.codex/agents/worker.toml` | 範囲を限定した実装と検証 |
| Reviewer | `~/.codex/agents/reviewer.toml` | 完了した変更の独立レビュー |

## 2. 役割ごとの設定

### Explorer：必要な範囲だけを調査する

Explorerは、関連する実装が不明な場合や、複数のモジュール・依存関係を調べる必要がある場合に利用する。読み取り専用とし、関連ファイル、現在の挙動、変更候補、リスクなどを簡潔に報告させる。

`~/.codex/agents/explorer.toml`：

```toml
sandbox_mode = "read-only"

developer_instructions = """
Investigate only what is necessary for the assigned task.

Identify:
- relevant files and symbols
- current behavior
- dependencies and call flow
- existing implementation patterns
- relevant tests
- likely change points
- important risks or uncertainty

Prefer targeted search and inspection over broad repository reading.

Do not modify files.

Keep the response concise.
Return findings, not a full implementation proposal,
unless specifically requested.
"""
```

調査結果を要約して親エージェントへ返すことで、親が大量のファイルを直接読み込む必要を減らせる。ただし、Explorerにも推論が発生するため、対象ファイルと変更内容がすでに明確な小さな作業では利用しない。

### Worker：実装と検証をまとめて担当する

Workerには、必要な挙動と対象範囲が明確になった実装を任せる。変更を必要最小限に留め、無関係なリファクタリングや抽象化を避ける。検証もWorkerの担当に含める。

`~/.codex/agents/worker.toml`：

```toml
developer_instructions = """
Implement only the assigned scope.

Before changing code:
- inspect the relevant existing implementation
- follow established repository conventions

During implementation:
- prefer the smallest correct change
- avoid unrelated refactoring
- avoid introducing new abstractions unless necessary
- preserve existing behavior outside the requested change

Validation:
- run focused validation appropriate to the change
- do not repeatedly run broad test suites without a reason

Report:
- files changed
- important implementation decisions
- validation performed
- remaining uncertainty

If a significant architectural or product decision is required,
report it to the parent instead of expanding the scope yourself.
"""
```

検証は、変更に適した狭い範囲から始める。広範なテストを理由なく繰り返さないことで、実行時間やログの処理に伴う負担を抑えられる。

### Reviewer：実害のある問題を優先する

Reviewerは、非自明な変更や、独立した確認によって重要な不具合を発見できる見込みがある場合に利用する。誤動作、要件違反、回帰、セキュリティ、データ整合性などを優先し、主観的な好みや無関係な改善案は対象から外す。

`~/.codex/agents/reviewer.toml`：

```toml
sandbox_mode = "read-only"

developer_instructions = """
Review only the completed change and directly relevant surrounding code.

Prioritize:
1. incorrect behavior
2. requirement violations
3. regressions
4. security or data integrity issues
5. important missing tests

Ignore:
- subjective style preferences
- speculative improvements
- unrelated refactoring opportunities
- minor issues already enforced by automated tooling

For each meaningful finding provide:
- severity
- location
- realistic failure scenario
- recommended fix

If there are no meaningful findings, say so concisely.

Do not modify files.
"""
```

指摘の対象を絞ることで、重要性の低い指摘による修正の繰り返しを避ける。機械的な変更や小さく低リスクな編集では、独立レビューを省略する。

### Testerを独立させない理由

汎用的な初期構成では、Testerを常設せず、実装と検証をWorkerへまとめる。

```text
Worker
 ├─ 実装
 └─ 変更に応じた検証
```

小さな変更では、検証のためだけに別のエージェントを起動し、結果を要約して親へ返す負担が、委譲の利点を上回る場合がある。大規模なログ解析など、分離する価値がある作業だけを必要に応じて別のエージェントへ委譲する。

## 3. AGENTS.mdで運用条件を明記する

役割を定義するだけでは、不要な委譲を防げない。`AGENTS.md`には、サブエージェントを使う条件と使わない条件、並列化、検証、報告の方針を記述する。

```markdown
# Development workflow

Make the smallest correct change that satisfies the request.

## Subagent policy

Subagents are a tool for reducing total work, not a mandatory workflow.

Do not spawn a subagent when the task can be completed
quickly and confidently in the current thread.

### Explorer

Use an explorer when:
- the relevant implementation is unclear
- several modules may be involved
- dependency or call-flow investigation is required
- repository exploration would add substantial context to the main thread

Do not use an explorer when:
- the relevant file and implementation are already known
- the change is small and local

### Worker

Use a worker for a clearly bounded implementation task when
delegation meaningfully reduces main-thread work.

For small changes, the primary agent may implement directly.

Do not spawn multiple workers that modify overlapping code.

### Reviewer

Use a reviewer for non-trivial changes where an independent
review is likely to catch meaningful defects.

Skip independent review for trivial mechanical changes,
formatting-only changes, or very small low-risk edits.

## Parallelism

Prefer at most one or two active subagents.

Parallelize only independent work.

Do not parallelize work merely because additional agent slots
are available.

## Validation

Start with the narrowest meaningful validation.

Broaden validation only when:
- focused validation fails
- the change has broad impact
- repository requirements explicitly require it
- there is a concrete regression risk

Do not repeatedly run the same checks without a reason.

## Context efficiency

Keep subagent assignments narrow.

Ask subagents to return conclusions and relevant evidence,
not large raw logs or exhaustive file contents.

Do not duplicate investigation already completed by another agent.
```

特に重要なのは、短時間で確実に完了できる作業ではサブエージェントを起動しないこと、すでに終わった調査を重複して行わないこと、報告を結論と必要な根拠に絞ることである。

## 4. 作業内容に応じた使い分け

以下は、作業の規模と不確実性に応じた運用例である。固定の手順として毎回すべての役割を使う必要はない。

| 作業例 | 担当の目安 | 委譲の目的 |
| --- | --- | --- |
| READMEの誤字修正 | 親エージェントが直接修正 | 小さな作業を短時間で完了する |
| APIの500エラーの調査・修正 | Explorerで調査し、親またはWorkerで修正 | 原因と関連コードを絞り込む |
| 認証方式の変更 | 必要に応じてExplorer、Worker、Reviewerを利用 | 調査・実装・独立レビューを分担する |

並列化は独立した作業に限定する。利用可能な実行枠があるという理由だけで、エージェントを追加しない。

## 5. モデルと推論強度の選び方

### 初期設定はLuna mediumに揃える

汎用的な出発点として、Explorer、Worker、Reviewerの既定値を共通にする。

```toml
default_subagent_model = "gpt-6-luna"
default_subagent_reasoning_effort = "medium"
```

`low`は細かな編集や明確な問題への対応、`medium`は明確な指示に沿った作成や既存成果物の変更を想定する。調査だけでなく実装にも同じ既定値を使うなら、まず`medium`から始め、作業結果を見ながら調整する。

### 必要に応じて役割ごとに調整する

利用量をさらに抑えたい場合は、各役割の`config_file`内でモデルや推論強度を上書きする構成も考えられる。

| 役割 | モデル | 推論強度の例 |
| --- | --- | --- |
| Explorer | `gpt-6-luna` | `low` |
| Worker | `gpt-6-luna` | `medium` |
| Reviewer | `gpt-6-luna` | `medium` |

最初から細かく分けるより、共通設定で運用し、調査や実装の品質を確認してから変更する方が設定を管理しやすい。

### 親エージェントとの分担

親エージェントにGPT-6.1 Solを使う場合は、明確に切り出せる下位タスクをLunaへ委譲する構成になる。

```text
GPT-6.1 Sol（親エージェント）
 ├─ Luna Explorer：調査
 ├─ Luna Worker：実装・検証
 └─ Luna Reviewer：独立レビュー
```

親は全体の判断と結果の統合を担当し、サブエージェントは割り当てられた範囲に集中する。利用量への効果は、委譲する作業の規模、起動回数、情報の受け渡し量によって変わる。

## 6. 導入時の設定と運用方針

初期設定の要点は次のとおりである。各役割の定義は「基本設定」の設定例を併せて使用する。

```toml
[agents]
enabled = true

default_subagent_model = "gpt-6-luna"
default_subagent_reasoning_effort = "medium"

max_concurrent_threads_per_session = 2
```

- 小さな作業は、親エージェントが直接処理する。
- 関連実装が不明な場合は、Explorerで必要な範囲を調べる。
- 範囲を明確に切り出せる実装は、Workerへ委譲する。
- 独立レビューの価値がある変更には、Reviewerを利用する。
- 検証は狭い範囲から始め、理由がある場合にだけ広げる。
- 調査の重複、不要な起動、大量のログの受け渡しを避ける。

利用量を抑えるうえでは、モデルの選択に加え、サブエージェントを起動しない条件を`AGENTS.md`に明記することが重要である。

## 参考資料

- [モデル選択ガイド](https://developers.openai.com/api/docs/guides/model-selection)
- [Codex設定リファレンス](https://developers.openai.com/ja-JP/docs/config-file/config-reference)
- [モデル利用ガイド](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-6.1-sol)
- [マルチエージェントガイド](https://developers.openai.com/api/docs/guides/responses-multi-agent)
