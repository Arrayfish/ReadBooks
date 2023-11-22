# Rustのフレームワークやクレートに関するメモ

## actix_webフレームワーク

rustでwebアプリケーションを作成する時に使用する。
似たようなフレームワークにaxumがある。
actixというアクターモデル？のフレームワーク上に構成されていたが、現在ではほぼ別物になっている。

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