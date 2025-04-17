# Github Copilotについてのメモ

## copilot instructions

Githubにカスタムのインストラクションを追加することができる機能  
.github/copilot-instructions.mdにあるファイルを参照して、カスタムインストラクションを作成することができる。

[公式ドキュメント](https://docs.github.com/ja/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)

しばらくは.git/info/excludeでgitから除外て調査する
参考にしたファイルからpythonであまり使用しない表現を除外している

### プロンプトファイル

`.github/prompts`ディレクトリに、フィル名が`*.prompt.md`のファイルを追加する。  
目的ごとに、参照するプロンプトのファイルを分けることができる。  
vscodeで使用するときは明示的に指定する必要がある。


## Agentモードメモ

- 最初に参照する範囲を指定するのが面倒臭い -> これ必要か？
- コードを見てドキュメントを生成してください。とか矛盾がある記述を修正してください。などの粒度の命令だとその通りに実行できない。
- ファイルのどの部分が示すように命令してもどのファイルかしか教えてくれないっぽい？コードを出力するように命令するか？