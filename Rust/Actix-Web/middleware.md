# [Actix Web - Middleware](https://actix.rs/docs/middleware)

App, Scope, Resourceに追加して使用することが出来る。
登録順とは逆の順番で実行される。  
middlewareはService traitとTransform traitを実装した型である。
公式サイトのサンプルコードのService traitの中だけいじれば良さそう。

他のフレームワークと同じ、リクエストとレスポンスの処理に対して追加の処理を付け加えることが出来る。

よくわからないけれど、シンプルなものならwrap_fn()の中でラムダ関数で実装できるらしい。
