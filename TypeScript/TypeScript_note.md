# TypeScriptに関してのメモ

## jest

テスト対象のクラスで使用されていて、非同期でテスト後に残ってしまう邪魔なライブラリがある場合はファイルの最初で`jest.mock()`によってモック化して無効化する。

spyは実際に機能してほしいけれど、呼ばれた時の情報が欲しい時に使用する。

一回ごとに呼び出し履歴などをクリアしたい場合は`jest.clearAllMocks()`を使用する。

jestではオブジェクトの一部一致や値の種類だけをチェックする方法もある。
`expect().toEqual(expect.objectContains())`

## nestjs

Webアプリケーションのフレームワーク、大規模開発向け

### test
テストの時に`moduleRef.get<ClassName>(ClassName)`でモジュールのインスタンスを作っておくと、各テストのArrangeで好きな`jest.fn()`を入れることができる。

## Lambdaへのデプロイ

[TypeScript による Lambda 関数の作成](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/lambda-typescript.html)
[Node.js による Lambda 関数の構築](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/lambda-nodejs.html)