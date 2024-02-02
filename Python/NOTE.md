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