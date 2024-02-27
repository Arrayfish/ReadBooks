# [actix_webフレームワーク](https://actix.rs/)

rustでwebアプリケーションを作成する時に使用する。
似たようなフレームワークにaxumがある。
actixというアクターモデル？のフレームワーク上に構成されていたが、現在ではほぼ別物になっている。

## middlewares

### actix_session

セッション管理をする。したのactix_identityで使用する
ユーザについて色々な情報を保持することができる？

### [actix-extras](https://github.com/actix/actix-extras#readme)

actix_webをサポートするクレート群

### actix-identity

ログイン管理をしてくれる
actix-sessionの上に構築されている
あくまでログイン管理だけなので、認証部分は自分で作成する必要がある。

## app_data()

アプリケーション全体で共有するデータを設定するための関数

それぞれのワーカースレッドの中で独立して作成されるので、ワーカースレッド間で共有する場合には最初に作成してクローンする必要がある。  
例: 
```rust
let counter = web::Data::new(AppStateWithCounter {
    counter: Mutex::new(0),
});

HttpServer::new(move || {
    // move counter object into the closure and clone for each worker
    App::new()
        .app_data(counter.clone())
        .route("/", web::get().to(handler))
})
```
