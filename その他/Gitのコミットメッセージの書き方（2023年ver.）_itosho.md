# Gitのコミットメッセージの書き方（2023年ver.）

## 基本フォーマット

[Semantic Commit Message](https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716)
を参考にしているらしい

- format: `<Type(required)>: <Emoji(option)> #<Issure Numnber(recommended)> <Title(required)>`
- e.g.) `feat: ✨ #123 ログイン機能を実装する`
- descriptionは任意  
  vscodeでは2行目を空行にすることで3行目からdescriptionに。cliでは-mをもう一度使うとdescriptionに

## Type
[Semantic Commit Message](https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716)
と同じ

- chore
  - タスクランナーのファイルなどプロダクションに影響のない修正
- docs
  - ドキュメントの更新
- feat
  - ユーザ向けの機能の追加や変更
- fix
  - ユーザ向けの不具合の修正
- refactor
  - リファクタリングを目的とした修正
- style
  - フォーマットなどのスタイルに関する修正
- test
  - テストコードの追加や修正

## Issure Number

- そのコミットに紐づくIssure番号
  - リンクになってトラッキングがしやすくなる
- Issureを作っていない場合やhotfixの場合は省略可能とする.

## Subject

- 変更内容を書く
- 現在系で書く  
  e.g.) NG: 〜した, OK: 〜をする
