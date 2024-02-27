# [Actix Web - Middleware](https://actix.rs/docs/middleware)

App, Scope, Resourceに追加して使用することが出来る。
登録順とは逆の順番で実行される。  
middlewareはService traitとTransform traitを実装した型である。
公式サイトのサンプルコードのService traitの中だけいじれば良さそう。

他のフレームワークと同じ、リクエストとレスポンスの処理に対して追加の処理を付け加えることが出来る。

よくわからないけれど、シンプルなものならwrap_fn()の中でラムダ関数で実装できるらしい。

## Service traitの中身の説明

call()メソッドの中の `let fut = self.service.call(req);` で下位のリクエストを処理している。  
リクエストの処理前に実行する処理を書く場合は、この行の前に書く。

Box::pin()は非同期処理のブロック(`async move{}`)の部分をヒープの中の特定のアドレスに固定する役割らしい。意味が分からない。自己参照する場合に有効などの情報が出てきたが、まだ理解できていない。  
非同期rustのページを読むと何かわかるかもしれない。