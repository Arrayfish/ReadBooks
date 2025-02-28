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
