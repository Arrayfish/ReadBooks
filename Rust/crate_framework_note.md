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

詳しくはディレクトリを参照

- 非同期に最初から対応したORMマッパー
- sqlxを使用している。
- cliでテーブル定義からmodel(エンティティ)を生成できる
- cliでアクティブレコードのようにテーブルに対応するモデル毎にメソッドが自動で提供される。

## dotenvy

dotenvクレートとunmaintainanceの状態になっているので、dotenvからforkされたこちらを使うのがベター

## [anyhow](https://docs.rs/anyhow/latest/anyhow/)

エラー処理を簡単にするためのクレート

関数の戻り値の型を`Result<T, anyhow::Error>`か同じ意味の`anyhow::Result<T>`にすることで、std::error::Errorトレートを実装しているどんなエラーでも返せるようになる。  
失敗しうる関数(Result型を返す)を呼び出す時に最後に?をつけることで、エラーをそのまま返すことができる。  

`use anyhow::Context`を使用して、関数に`.context("Some Error Message")`をつけることで、エラーの内容を追加することができる。

`anyhow::bail!("Error message")`マクロで早期にエラーを返すことができる。

## [thiserror](https://docs.rs/thiserror/latest/thiserror/)

rustの標準ライブラリのエラー`std::error::Error`に対する便利なマクロを提供するクレート

エラーのenumを作成する際に、`#[derive(thiserror::Error)]`をつけることで、エラーの型を簡単に作成できる。
例

```rust
use thiserror::Error;
#[derive(Error, Debug)]
pub enum MyError {
    #[error("An error occurred: {0}")]
    SomeError(String),
    #[error("Another error occurred")]
    AnotherError,
}
```

## [confy](https://docs.rs/confy/latest/confy/index.html)

設定ファイルの読み書きをするためのクレート
他のクレートと比べてシンプルな構成
