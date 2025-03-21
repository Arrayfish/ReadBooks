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

Pythonのdatetimeオブジェクトにはタイムゾーンを持たないnativeなdatetimeとタイムゾーンを持つawareなdatetimeがある。

datetimeにタイムゾーンをつけたり、別のタイムゾーンに変換したりするのには次の関数を使う

astimezone(): 元々、タイムゾーン情報がついているawareなdatetimeオブジェクトを別のタイムゾーンに変更する場合

pytz.timezone().localize: タイムゾーン情報がないnativeのdatetimeオブジェクトにタイムゾーン情報をつける場合

nativeなdatetimeに対してastimezone()を使用すると、nativeなdatetimeのタイムゾーンがサーバのタイムゾーンだと解釈して時間の調整をするので、ローカルとサーバとでタイムゾーンが異なる場合には注意が必要。
基本的にはnativeなdatetimeについてはastimezone()を使ってはならない

replace()という直接datetimeのオブジェクトを編集する関数があるが、直接nativeなdatetimeのreplaceでpytz("Asia/Tokyo")をつけると、JSTではなく、+9:19のLMTというタイムゾーンになる。

## ジェネリクス

### TypeVar

型ヒントシステムで使用される、型変数を定義するための機能  
型の一貫性を保証するために使用される

```python
from typing import TypeVar

T = TypeVar('T')

def identity(arg: T) -> T:
    return arg
```

### Generic

ジェネリッククラスを定義するために使用する  
クラス内で型変数を使用できるようにする  
TypeVarと同時に使用する

```python
from typing import Generic, TypeVar

T = TypeVar('T')

class Container(Generic[T]):
    def __init__(self, item: T):
        self.item = item

    def get_item(self) -> T:
        return self.item