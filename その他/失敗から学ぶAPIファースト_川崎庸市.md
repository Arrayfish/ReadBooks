#  失敗から学ぶAPIファースト / API first learning from failure
https://speakerdeck.com/yokawasa/api-first-learning-from-failure?slide=2

## NOTE

APIファースト
Beyond the 12FA(Twelve-Factor App)の中に入っている。

APIファーストのあいまいな概念
- 開発前にAPIスキーマ設計
- システム連携より前にAPI開発
- API設計より前にビジネス要件定義

MACHアーキテクチャ
> こんな単語あったんだ。
- Microservices-based
- API first
- Cloud nativ saas
- headless


APIを先に決定することで、テストが開発の前半で実行できて並行して処理できる部分が多くなる。
フィードバックが早めに得られる。
> まあ、インターフェイスを先に決めておけば楽だよってことだよね。

> API仕様からドキュメント、テスト、モック作成の部分はどっかでちゃんとやり方を知りたい。
> できたらコードからAPI仕様を生成したい。

APIをプロダクトの一部ではなく、API自体をプロダクトとして考えてライフサイクル全体で管理する。

APIファーストな開発ワークフロー
