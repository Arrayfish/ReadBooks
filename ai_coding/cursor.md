# cursor

## [rules](https://docs.cursor.com/context/rules)

github copilotのcopilot-instructionsのようなもの。もっと詳しく作成可能になる

/Generate で会話からCursorのルールを生成することができる。

## [worktrees]()

gitのworktree機能を使って、複数の実装ができる？
実装が終わると、applyボタンが出てきて、押すとメインがわの画面のブランチに変更が適用される
機能的には複数の実装を見比べて良いのを採用するためのものか？
多分これ、gitで複製したものをみているので、gitでworktrees.jsonを管理していない場合は読み込まれない？
gitで管理していないruleが読み込まれないが、次のスクリプトでworktree作成時にコピーすることができる

```json
{
  "setup-worktree": [
    "cp -r .cursor/rules $WORKTREE_PATH/.cursor/rules"
  ]
}
```
