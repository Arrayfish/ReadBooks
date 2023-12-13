# Rustのフレームワークやクレートに関するメモ

## [actix_webフレームワーク](https://actix.rs/)

rustでwebアプリケーションを作成する時に使用する。
似たようなフレームワークにaxumがある。
actixというアクターモデル？のフレームワーク上に構成されていたが、現在ではほぼ別物になっている。

### [middleware](https://actix.rs/docs/middleware)

#### actix_session

セッション管理をする。したのactix_identityで使用する
ユーザについて色々な情報を保持することができる？

### [actix-extras](https://github.com/actix/actix-extras#readme)

actix_webをサポートするクレート群

#### actix-identity

ログイン管理をしてくれる
actix-sessionの上に構築されている
あくまでログイン管理だけなので、認証部分は自分で作成する必要がある。

## ユーザ認証に使えそうなクレート

### librauth

### この[サイト](https://blog.logrocket.com/9-rust-authentication-libraries-that-are-ready-for-production/)
複数のサイトが載っているが、2020年のサイトなのでちゃんと自分でも調べる

## tracing クレート

非同期アプリケーション用のログのクレート  
tokioなどの非同期システムで使う  
開始時刻と終了時刻があり、実行の流れによって、でたり入ったりできる。

## unigode_segmentation::UnicodeSegmentation::Graphemes

海外の文字で文字としては2つ分だが、表示的には1文字分の文字がある。それをうまく処理できる。

## tracing_actix_web::TracingLogger

見るからにロガーだが、どんな機能があったのか忘れた。  
actix_web::Appの.wrap()に入れて使う。ミドルウェア？

## utopia
- OpenAPIをマクロの記述から生成する。  
- 実際にURLからswaggerを見るにはutopia-swagger-uiクレートを使う。

## SeaORM

- 非同期に最初から対応したORMマッパー
- sqlxを使用している。
- cliでテーブル定義からmodel(エンティティ)を生成できる
- cliでActiveレコードのようにテーブルに対応するモデル毎にメソッドが自動で提供される。

### ActiveModel
ActiveValueをプロパティに持つモデル。
ActiveValueにはNotSet, Unchanged(val), Set(val)の3つの種類がある。
save()ではprimarykeyがNotSetの場合にはINSERTに、それ以外の場合はUPDATEになる。
update()ではSetのものしか更新しないので、reset()などで強制的にSetにする必要がある。