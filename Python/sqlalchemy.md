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

## datetime型について

モデルで`timezone = True`を指定すると、datetime型のカラムがタイムゾーンを持つようになる。

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

### Select

テーブルのオブジェクトを使ったやり方とORMのエンティティを使った選択方法がある。
ORMエンティティを使ったやり方の場合はデータがORMエンティティに入る。
1レコードだけ必要な場合はexecute()の代わりにselect().first()を使う。
```python
user = session.scalars(select(User)).first()
```

何も考えずにselect(user_table)を実行すると、全てのカラムを取得する。

ORMエンティティを使用した場合に、select()に複数のエンティティを渡し、where()で結合条件を渡すと複数のテーブルからデータを取得できる。

select().join()やselect().join_from()で結合することができる。

subqueryとCTE(Common Table Expression)という似たような機能がある。ORMでも使えるらしい。よくわからないがalias()を使うらしい

Insert, DeleteはORMだと内部的に実行される？
ただし、ちゃんとSessionのトランザクションに乗るので勝手にコミットされないっぽい
unit of workパターンというものがあるらしいよくわからない。

### ORM

ORMのエンティティをオブジェクトとして生成すると最初はtransient状態になる。
その後にテーブルに挿入されるとpersistent状態になる。
セッションを閉じた後はdetached状態になる。再度属性にアクセスする時には新しいセッションを作成する必要がある。

DBに未反映のInsertに関してはSession.newというプロパティで取得可能。

現在のセッションの変更をDBに反映することをflushという。(トランザクションはまだコミットされていない)
通常はautoflush機能があるので、手動でflush()を呼ぶ必要はない。

DBに未反映の変更がある場合はSessionはdirty状態であり、Session.dirtyでdirty状態かどうかを確認できる。
autoflushがONの場合は、次にDBにSELECTする時に自動的にflush()が呼ばれる。

Session.get(<エンティティ>, <プライマリーキー>)でエンティティを取得できる。

relashonship()でリレーションを作成した時に、普通だrelationshipに指定した属性にアクセスした段階で自動的にSELECTが発行される。
これを遅延ロードという。

ただし、これはN+1問題を引き起こす可能性があるので、色々と他のロード方法がある。
詳しくは後で書く
