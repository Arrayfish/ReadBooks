# [locust](https://locust.io/)

Webサイトの負荷テスト用のライブラリ  
locustをpipなどでインストールした後で、`locust`コマンドを実行するとローカルサーバが立ち上がり、そこからテストを実行できます。

## locustファイルの書き方

```python
import time
from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(1, 5)

    @task
    def hello_world(self):
        self.client.get("/hello")
        self.client.get("/world")

    @task(3)
    def view_items(self):
        for item_id in range(10):
            self.client.get(f"/item?id={item_id}", name="/item")
            time.sleep(1)

    def on_start(self):
        self.client.post("/login", json={"username":"foo", "password":"bar"})
```

HttpUserを継承することで、class.clientでHTTPのセッションにアクセス可能

wait_timeは、ユーザーが次のタスクを実行するまでの待機時間を設定します。  
現在の場合は、ユーザは一度タスクを実行してから1秒から5秒のランダムな時間を待機します。

`@task`デコレータがついている関数がメインのテスト内容となる。
この関数の中では順番にコードが実行されます。

一回の試行ごとに、ユーザは`@task`デコレータがついている関数のうちから一つをランダムに選んで実行します。  
`@task`デコレータの引数に数値を指定することで、その関数が選ばれる確率を変更できます。  
この場合は、hello_worldよりview_itemの方が3倍選ばれやすい

### locustの自動生成

ネットワークのなんかしらのファイルである。harファイルからlocustファイルを作ることもできる

### Userclassの設定

#### wait timeの設定

between以外にも、実行後の待機時間を設定することができる

- constant: 一定の時間待機
- between: 一定の範囲でランダムに待機
- constant_throughput: 1秒間に少なくとも指定回数のリクエストが実行される
- constant_pracing: 指定秒に1回リクエストが実行される