# [propertyデコレータ](https://docs.python.org/ja/3/library/functions.html#property)

Pythonのクラスでプロパティを定義するためには、propertyデコレータを使う方法がある。propertyデコレータを使うと、インスタンス変数の値を取得したり設定したりする際に、メソッドを呼び出すようにすることができる。

以下の例では、propertyデコレータを使って、インスタンス変数の値を取得するためのgetterメソッドと、設定するためのsetterメソッドを定義している。

```python
class MyClass:
    def __init__(self):
        self._x = None

    @property
    def x(self):
        return self._x

    @x.setter
    def x(self, value):
        self._x = value

obj = MyClass()
obj.x = 100
print(obj.x)  # 100
```
