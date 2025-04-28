# [SeaORM](https://www.sea-ql.org/SeaORM/)

sqlx上に構築されたORM

テーブルに相当する`Entity`を定義することでCRUDを簡単に行うことができる

Rustの構造体(`Model`)経由でデータの操作を行う。  
`Model`は読み込み専用で、変更を加える場合は`ActiveModel`を使用する。これは各属性のメタデータを保持している。

Webフレームワークと連携する例が色々と提供されている。

## [インストール](https://www.sea-ql.org/SeaORM/docs/install-and-config/database-and-async-runtime/)

featuresにはDATABASE_DRIVERとASYNC_RUNTIMEを指定する。あと"macro"もEntityの自動生成に必要  
DATABASE_DRIVERは使用するDBの種類によって異なり、sqlx-mysql, sqlx-postgres, sqlx-sqliteがある。  
ASYNC_RUNTIMEは非同期ランタイムと、使用するtlsライブラリの組み合わせとなる。  
非同期ランタイムはasync-stdとtokio、tlsライブラリにはnative-tlsとrustlsがある。

例)

```toml
sea-orm = { version = "1.1.0", features = [ <DATABASE_DRIVER>, <ASYNC_RUNTIME>, "macros" ] }
```

## マイグレーション

cliでやる方法とコード上から行う方法がある。開発時は起動時にコード上から行う方法が便利。

### ActiveModel
ActiveValueをプロパティに持つモデル。
ActiveValueにはNotSet, Unchanged(val), Set(val)の3つの種類がある。
save()ではprimarykeyがNotSetの場合にはINSERTに、それ以外の場合はUPDATEになる。
update()ではSetのものしか更新しないので、reset()などで強制的にSetにする必要がある。
