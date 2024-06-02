# Pythonテストについて

## テストライブラリ
- unittest
- docstring
- pytest

## pytest

### pytest-mock
unittest.mockのラッパー
fixtureというものでモックができる？

#### モックする時にハマりやすいポイント
- import hoge と import されているモジュールの hoge.fuga を patch するには hoge.fuga を指定する
- from hoge import fuga と import されている fuga を patch するには <import 文を書いている方のモジュール名>.fuga を指定する
例) some_module.pyの中で`from another_module import another_func`と呼ばれている関数をmockした場合には
`mock.path("some_module.another_func")`としてmockする

https://qiita.com/Chanmoro/items/69f401ddbe41e818a8cf

### 疑問
特定の1ファイルのみインポートされているモジュールは上の方法でモックできるが、モジュール自体をモックして、インポートされている全てのファイルでの動作をmockするためにはどうすればいい？  
その方法はモジュールのファイルに直書きされているコードを実行を無効化できるか？

### モジュールのモックの実験
モジュールから関数のみをインポートしている場合にはモジュールの直下に書かれているコードは実行されない。 

### テストのグループ分け

テストのクラスや関数の前に`@pytest.mark.<identifer>`をつけるとテストのグループ分けが可能で`pytest -m "<identifer>"`でそのグループのテストのみを実行可能  
`pytest -m "not <identifer>"`で特定のグループのみを実行しないことも可能。組み合わせも可。

### sqlalchemyを使用してDBと結合してテストするとき

fixtureを設定する
```python
from sqlalchemy import create_engine
from sqlalchemy.engine.url import URL
from sqlalchemy.orm import Session
@pytest.fixture(scope="module")
def db_session():
    _driver_name = "mysql+pymysql"
    host = os.environ.get("DB_HOST")
    port = os.environ.get("DB_PORT")
    database = os.environ.get("DB_DATABASE")
    username = os.environ.get("DB_USER_NAME")
    password = os.environ.get("DB_PASSWORD")
    url = URL.create(_driver_name, username, password, host, port, database)
    print("url: ",url)
    engine = create_engine(url)
    with Session(engine) as session:
        yield session
        session.rollback()
```

途中で反映したい場合は`db_session.flush()`を実行すること

