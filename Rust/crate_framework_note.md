# Rustのフレームワークやクレートに関するメモ

## [lib.rs](https://lib.rs/)

様々な種類のクレートを紹介するサイト  
カテゴリごとの検索や、人気のクレートなどが見れる。

## [Blessed.rs](https://blessed.rs/crates)

よく使用されるクレート紹介サイト

## ユーザ認証に使えそうなクレート

### librauth

### この[サイト](https://blog.logrocket.com/9-rust-authentication-libraries-that-are-ready-for-production/)
複数のサイトが載っているが、2020年のサイトなのでちゃんと自分でも調べる

## jsonwebtoken
lib.rsで一番上に出てきた。調べ中

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

## dotenvy

dotenvクレートとunmaintainanceの状態になっているので、dotenvからforkされたこちらを使うのがベター
