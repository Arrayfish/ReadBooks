## Python

Pythonでのコーディングにおける一般的なベストプラクティスをまとめます。

### 方針

- 最初に型と、それを処理する関数のインターフェースを考える
- コードのコメントとして、そのファイルがどういう仕様化を可能な限り明記する
- 実装が内部状態を持たないとき、 class による実装を避けて関数を優先する
- 副作用を抽象するために、アダプタパターンで外部依存を抽象し、テストではインメモリなアダプタで処理する

### 型の使用方針

1. 具体的な型を使用
   - Any の使用を避ける
   - Pydantic や dataclasses を活用
   - 型アノテーションを積極的に利用
   - mypy で型チェックを行う

### エラー処理

1. エラー型の定義
   - 具体的なケースを列挙
   - エラーメッセージを含める
   - 型の網羅性チェックを活用

2. エラー処理ルーチンの実装
   - エラーを適切にハンドリングするメカニズムを導入
   - ログにエラー情報を記録する

### 実装パターン

1. 関数ベース（状態を持たない場合）

   ```python
   # インターフェース
   from typing import Protocol   
   import datetime  

   class Logger(Protocol):
       def log(self, message: str) -> None:
           ...

   # 実装
   def create_logger() -> Logger:
       return {
           "log": lambda message: print(f'[{datetime.datetime.now().isoformat()}] {message}')
       }
   ```

2. classベース（状態を持つ場合）

   ```python
   # インターフェース
   class Cache(Protocol):
       def get(self, key: str) -> T | None:
           ...
       def set(self, key: str, value: T) -> None:
           ...

   class TimeBasedCache(Cache):
       def __init__(self, ttl_ms: int) -> None:
           self.ttl_ms = ttl_ms
           self.items: dict[str, tuple[T, int]] = {}

       def get(self, key: str) -> T | None:
           item = self.items.get(key)
           if not item or time.time() > item[1]:
               return None
           return item[0]

       def set(self, key: str, value: T) -> None:
           self.items[key] = (value, time.time() + self.ttl_ms)
   ```

3. Adapterパターン（外部依存の抽象化）

  ```python
  from typing import Callable, TypeVar, Generic, Any
  import aiohttp
  import asyncio

  # 型定義
  T = TypeVar('T')

  class Result(Generic[T]):
      def __init__(self, value: T | None, error: dict[str, Any] | None):
          self.value = value
          self.error = error

      @staticmethod
      def ok(value: T) -> 'Result[T]':
          return Result(value=value, error=None)

      @staticmethod
      def err(error: dict[str, Any]) -> 'Result[T]':
          return Result(value=None, error=error)

  # Fetcher型
  Fetcher = Callable[[str], asyncio.Future]

  # 実装
  def create_fetcher(headers: dict[str, str]) -> Fetcher:
      async def fetcher(path: str) -> Result:
          try:
              async with aiohttp.ClientSession(headers=headers) as session:
                  async with session.get(path) as response:
                      if response.status != 200:
                          return Result.err({
                              "type": "network",
                              "message": f"HTTP error: {response.status}"
                          })
                      data = await response.json()
                      return Result.ok(data)
          except Exception as error:
              return Result.err({
                  "type": "network",
                  "message": str(error)
              })
      return fetcher

  # 利用
  class ApiClient:
      def __init__(self, get_data: Fetcher, base_url: str):
          self.get_data = get_data
          self.base_url = base_url

      async def get_user(self, user_id: str) -> Result:
          return await self.get_data(f"{self.base_url}/users/{user_id}")

  # 使用例
  async def main():
      headers = {"Authorization": "Bearer token"}
      fetcher = create_fetcher(headers)
      client = ApiClient(fetcher, "https://api.example.com")

      result = await client.get_user("123")
      if result.error:
          print(f"Error: {result.error}")
      else:
          print(f"User data: {result.value}")

  # 実行
  # asyncio.run(main())
  ```