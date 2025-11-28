# Github Copilotについてのメモ

## copilot instructions

Githubにカスタムのインストラクションを追加することができる機能  
.github/copilot-instructions.mdにあるファイルを参照して、カスタムインストラクションを作成することができる。

[公式ドキュメント](https://docs.github.com/ja/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)

しばらくは.git/info/excludeでgitから除外て調査する
参考にしたファイルからpythonであまり使用しない表現を除外している

## パス固有のinstructionsファイル

.cursor/rulesみたいなもの  
.github/instructionsディレクトリに、フィル名が`*.instructions.md`のファイルを追加する。
最初のセクションの`applyto:`で適用対象のファイルを指定できる。
[公式ドキュメント](https://docs.github.com/ja/copilot/how-tos/configure-custom-instructions/add-repository-instructions#creating-path-specific-custom-instruction)

## プロンプトファイル

`.github/prompts`ディレクトリに、フィル名が`*.prompt.md`のファイルを追加する。  
目的ごとに、参照するプロンプトのファイルを分けることができる。  
vscodeで使用するときは明示的に指定する必要がある。


## Agentモードメモ

- 最初に参照する範囲を指定するのが面倒臭い -> これ必要か？
- コードを見てドキュメントを生成してください。とか矛盾がある記述を修正してください。などの粒度の命令だとその通りに実行できない。
- ファイルのどの部分が示すように命令してもどのファイルかしか教えてくれないっぽい？コードを出力するように命令するか？

## MCP

Organizationの設定で、有効化しないと使えない。
設定を変えたら一旦vscodeを再起動した方が良さそう。