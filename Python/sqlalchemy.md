# [sqlalchemy](https://www.sqlalchemy.org/)について

pythonのORM  
Coreという機能とORMという二つの書き方がある。  
Coreはクエリビルダのような感じの機能でORMはそのままCoreの上で構築されたORMになる。  
二つを共存させることも可能  

## 踏み台サーバ越しにsshで接続する

今回は、sshにpemファイルを使用してパスワードは使用しない。

```python
from sqlalchemy import create_engine, text
from sshtunnel import SSHTunnelForwarder
from dotenv import load_dotenv
import os
load_dotenv()

SSH_PKEY = os.environ.get('SSH_PKEY')
SSH_ADDRESS = (os.environ.get('SSH_ADDRESS'), int(os.environ.get('SSH_PORT') or "22"))
SSH_USERNAME = os.environ.get('SSH_USERNAME')
SSH_REMOTE_BIND_ADDRESS = (os.environ.get('SSH_REMOTE_BIND_ADDRESS'), int(os.environ.get('SSH_REMOTE_BIND_PORT') or "3306"))
DB_USERNAME=os.environ.get('DB_USERNAME')
DB_PASSWORD=os.environ.get('DB_PASSWORD')
DATABASE_NAME=os.environ.get('DATABASE_NAME')

print(SSH_PKEY, SSH_ADDRESS, SSH_USERNAME, SSH_REMOTE_BIND_ADDRESS, DB_USERNAME, DB_PASSWORD, DATABASE_NAME)
SSHTunnelForwarder(
    SSH_ADDRESS,
    ssh_username=SSH_USERNAME,
    ssh_pkey=SSH_PKEY, # JUMP_SERVER_IPにホスト名を入れている(sshのconfigを設定している)場合はなくてもよい
    remote_bind_address=SSH_REMOTE_BIND_ADDRESS
) as server:
    print(server.local_bind_port)
    local_port = server.local_bind_port
    engine = create_engine(
        f'mysql+pymysql://{DB_USERNAME}:{DB_PASSWORD}@127.0.0.1:{local_port}/{DATABASE_NAME}'
    )
    sql = "SELECT * FROM ccr_db.freekey_user LIMIT 10;"

    with engine.connect() as conn:
        result = conn.execute(text(sql))
        for row in result:
            print(row)
```

## commit（）とflush()について

- commit()がその名の通りに変更をコミットする。

- flush()はテーブルへの一時的な反映で、これがないとコミット前にselectを使用しても取得ができない。
- rollback()で削除される。

- autoflushオプションででadd()のたびにflush()される

## [チュートリアル](https://docs.sqlalchemy.org/en/20/tutorial/index.html)のメモ

coreのconnection。"connection as you go"スタイルと"begin once"スタイル  
基本は"begin once"スタイルの方が良い  

Connection.execute()の第一引数に`:x`の形で変数を定義して、第二引数で辞書またはそのリストを渡すと代入できる

リストを代入した場合はinsert文がリストの長さ分実行される。これをexecutemenyという

同じことが、ORMのSessionでもできる.
Sessionは"Commit as you go"型である

MetaDataオブジェクトがアプリケーションにつき1つ存在するのが普通
大体は、モジュールレベルの変数として定義される

primary key制約とforeign key制約

declarative baseという機能を使うことで、ORMで使用するmaped classとTableオブジェクトをセットで作成できる。

metadataと同じようにregistryというものが、declarative base機能で生成され、Mapted class同士の連携に使用される。

新しい2.0からのDeclarativeBaseはPythonの型アノテーションやdataclassに対応している。

DBからTableクラスを作成するtable reflectionはskipした
次はWorking with Dataの章

Coreのインサートのやり方

デフォルトでinsertした時のプライマリキーとサーバデフォルトを返す
executeに、stmtとvalueを別々に渡すことができる。

途中でselectの説明で面倒になってきた