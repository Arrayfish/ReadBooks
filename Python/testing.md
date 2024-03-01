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

https://qiita.com/Chanmoro/items/69f401ddbe41e818a8cf

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
