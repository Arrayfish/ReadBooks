# [なぜThrottleではなくDebounceだったのか？](https://speakerdeck.com/yoshiori/nazethrottledehanakudebouncedatutanoka-700bing-lie-rikuesutotozhan-usabasaidoshi-zhuang-nosubete)

## ThrottleとDebounceの違い

- Throttle: 一定時間に一度だけ実行する。
- Debounce: 一定時間操作がなければ実行する。

## メモ

複数のプロセスを跨いでDebounce処理をするためにredisを使っていた。
redisはデフォルトでアトミックな処理ができるため、設定したユニークな値の有無でロックを実現していた。
debounceの待機時間のを動的に変化させる構築をしていて、その待機時間をredisのキーとして扱っていた。
