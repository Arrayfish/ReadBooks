# Pydantic

Pydanticはdataclassの強化版のようなライブラリ  
クラスのコンストラクタやバリデータが簡単に作成することができる  
[公式サイト](https://docs.pydantic.dev/latest/)  

## イミュータブルなクラスを作成する

```python
class FooBarModel(BaseModel):
    model_config = ConfigDict(frozen=True)

    a: str
    b: dict
```

## AwareDatetime型, NativeDatetime型

Pythonのdatetime型にはタイムゾーン情報を持っているawareなdatetime型と持っていないnaiveなdatetime型がある
Pydanticではこの二つを区別して扱うことができる

## PrivateAttr

プライベートなインスタンス変数を作りたい場合は`PrivateAttr`を使用する  

pydanticでは`PrivateAttr`をつけないと、_で始まる変数を利用することができない。

```python
class Foo(BaseModel):
    _private: PrivateAttr[str]
```

## default

`default`を使用することで、デフォルト値を設定することができる。  
デフォルト値が入力されるのはインスタンス時なので`@model_validator`などでデフォルト値を参照、変更することができる。
ただし、frozen=Trueの時は`model_validator`で変更できない。
そのほかに`model_post_init`を使用することで、インスタンス化後にデフォルト値を変更することができる。

```python
class Foo(BaseModel):
    a: str = Field(default=None)

    def model_post_init(self, __context: Any) -> None:
        """Override this method to perform additional initialization after `__init__` and `model_construct`.
        This is useful if you want to do some validation that requires the entire model to be initialized.
        """
        print(f"{__context=}")
        if self.a is None:
            self.a = "default"
```

## model_dumpの内容をキャメルケースで出力する

BaseModelに以下の設定を追加することで、入力するときにキャメルケースで入力できるようになる。  
`model_dump(by_alias=True)`を指定することで、エイリアス名で出力されます。
`model_dump(mode="json")`を指定することで、UUIDやdatetimeなどの型もJSONにできる形に変換されます。


```python
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
class Foo(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True
    )
```

## クラス変数を定義する

typingの`ClassVar`を使用することで、クラス変数を定義することができる。
```python
from typing import ClassVar
from pydantic import BaseModel

class User(BaseModel):
    id: int
    name: str
    TYPE: ClassVar[str] = "user"  # これはインスタンスのフィールドになりません
```
