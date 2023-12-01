# TypeScriptに関してのメモ

## jest

テスト対象のクラスで使用されていて、非同期でテスト後に残ってしまう邪魔なライブラリがある場合はファイルの最初で`jest.mock()`によってモック化して無効化する。

spyは実際に機能してほしいけれど、呼ばれた時の情報が欲しい時に使用する。

一回ごとに呼び出し履歴などをクリアしたい場合は`jest.clearAllMocks()`を使用する。

jestではオブジェクトの一部一致や値の種類だけをチェックする方法もある。
`expect().toEqual(expect.objectContains())`

## nestjs

### test
テストの時に`moduleRef.get<ClassName>(ClassName)`でモジュールのインスタンスを作っておくと、各テストのArrangeで好きな`jest.fn()`を入れることができる。