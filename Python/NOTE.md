# 雑多な何か

## [functool.wrap()](https://docs.python.org/ja/3/library/functools.html#functools.wraps)

デコレータを複数使用しても関数名やdocstringsが同じになるようになるデコレータ関数

```python
from functools import wraps
def my_decorator(f):
    @wraps(f)
    def wrapper(*args, **kwds):
        print('Calling decorated function')
        return f(*args, **kwds)
    return wrapper

@my_decorator
def example():
    """Docstring"""
    print('Called example function')
```

## PYTHONPATH環境変数

PYTHONPATH環境変数はPYTHONモジュールの探索パスを追加するもの。

## クラス変数

def __init__()の中で定義された変数はインスタンス変数になるが、クラス変数はクラスの中で定義された変数で、全てのインスタンスで共有される。

```python

class Dog:
    kind = 'canine'         # class variable shared by all instances

    def __init__(self, name):
        self.name = name    # instance variable unique to each instance
    
    def get_class_variable(self):
        return self.__class__.kind

```

## datetimeのタイムゾーンについて

```python
import pytz
from datetime import datetime

current_datetime = datetime.now()
current_datetime.astimezone(pytz.timezone("Asia/Tokyo"))

somedatetime = somedatetime.replace(hour=0, minute=0, second=0)

owner_created_at = owner_created_at.replace(tzinfo=timezone.utc)