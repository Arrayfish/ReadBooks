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