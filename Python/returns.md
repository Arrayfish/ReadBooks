# returns: Python関数型プログラミング用 ライブラリ

[Github](https://github.com/dry-python/returns)
[ドキュメント](https://returns.readthedocs.io/en/latest/index.html)

## NOTE

- 流石にResult型解かないと不便だからこのライブラリを採用したい。
- 使う型のことをcontainerと呼ぶらしい
- mypyを使っている場合はオプションを指定してインストールとtomlに追記が必要


## 主なコンテンツ

- Maybe型: | Noneの代わり?
- RequiresContext container: わからん。上の方のモジュールで依存が多いときに使うのか？
- Result型: 成功と失敗を表現するための型。成功時は値を持ち、失敗時はエラーメッセージを持つ。
- IO型: 副作用を持つ関数を扱うための型
- Future型: 非同期処理を扱うための型

## Maybe型

`@maybe`デコレータで`| None`の関数をこの型を返すように変更できる
`.bind_optional()`メソッドで、None以外の時だけ関数を実行できる

```python
maybe_number: Maybe[int] = opt_function().bind_optional(
  lambda number: number / 2,
)
```

## RequiresContext container

依存注入のためのコンテナ
依存が注入される関数返す?
あまりよくわからない

## Result型

鉄道志向プログラミングに関係する

成功するか失敗するかわからない関数を扱うための型
`@safe`デコレータを使うとResult型を返すようになる。
bindメソッドを使うと、入力がSuccessのときだけ関数を実行する

```python
import requests
from returns.result import Result, safe
from returns.pipeline import flow
from returns.pointfree import bind

def fetch_user_profile(user_id: int) -> Result['UserProfile',Exception]:
    return flow(
        user_id,
        _make_request,
        bind(_parse_json),
    )

@safe
def _make_request(user_id: int) -> requests.Response:
    # 本当はIOResultになるけど省略
    response = requests.get(f"/api/users/{user_id}")
    response.raise_for_status()
    return response

@safe
def _parse_json(response: requests.Response) -> "UserProfile":
    return response.json()
```

## IO型

純粋関数でない場合にこれが戻り値になる
純粋関数: 入力が同じなら出力も同じになる関数
純粋関数ではない例: ランダムな値を返す、環境変数から値をとる、DBアクセス, 外部APIを叩くなど、標準出力する
`@inpure`で戻り値をIO型にできる

```python
import random
import datetime as dt

from returns.io import IO

def get_random_number() -> IO[int]: # or use @impure
    return IO(random.randint(1, 10))

now: Callable[[], IO[dt.datetime]] = inpure(dt.datetime.now)

@impure
def return_and_show_next_number(previous: int) -> int:
    next_number = previous + 1
    print(next_number)
    return next_number
```

## IOResult型

IO型とResult型を組み合わせた型
副作用を持つ関数が成功または失敗する可能性がある場合に使用する
`@inpure_safe`デコレータを使うと、IO型とResult型の両方の特性を持つ関数を定義できる

```python
@impure_safe
def _make_request(user_id: int) -> requests.Response:
    response = requests.get(f'/api/users/{user_id}')
    response.raise_for_status()
    return response
```

## Future型

非同期処理を扱うための型
pythonでは非同期では次のような不都合がある。
- 同期関数から非同期関数を呼ぶことができない
- 非同期関数がエラーになると、全部のイベントループが止まってしまう可能性がある
- 多くのawaitを組み合わせるのが難しい
これらの問題を解決できる。
大体はFutureResult型として使われる。
`@future_safe`デコレータを使うとFutureResult型を返すようになる。

## map(), bind()

map()は通常の値を返す関数についての処理を行う。
bind()はコンテナを返す関数についての処理を行う。