# sqlalchemyについて

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