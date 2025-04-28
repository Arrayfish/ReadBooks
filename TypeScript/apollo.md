# [Apollo](https://www.apollographql.com/docs)

GraphQL用のライブラリ、クライアント向けのApollo Clientとサーバー向けのApollo Serverがある。

## [Apollo Server](https://www.apollographql.com/docs/apollo-server)

### schemaについて

```graphql
type Query{
    Author(id: ID!): Author
    books: [Book]
}

type Author{
    id: ID!
    name: String!
    books: [Book]
}
```

- not nullableなフィールドには`!`をつける
- ルート操作として`Query`と`Mutation`、`Subscription`がある
- スキーマのタイプには以下の種類がある
  - Scalar: プリミティブ
  - Object: 値の集まり、ルート操作もここに含まれる
  - Input: 階層的な入力を作ることができる特殊なオブジェクト
  - Enum
  - Union: 後述
  - Interface: 後述
- 独自のScalarを作ることもできる
- `@`で始まるものはディレクティブと呼ばれる、スキーマのフィールドにメタデータを追加するためのもの
  - 標準では`deprecated`, `skip`, `include`の3つのディレクティブのみ定義されている

#### Union

Unionは複数の型の複合

```graphql
union SearchResult = Book | Author
type Query{
    search(text: String!): SearchResult
}
```

Unionをクエリする場合

```graphql
query GetSearchResults {
  search(text: "Shakespeare") {
    __typename // ここにタイプ名が入る(Book or Author)
    ... on Book{
      title
    }
    ... on Author {
      name
    }
  }
}
```

Unionに対するリゾルバを作る場合

```typescript
const resolvers = {
  SearchResult: {
    __resolveType(obj, contextValue, info){
        if(obj.name){ // Only Author has name field
            return 'Author';
        }
        if(obj.title){ // Only Book has title field
            return 'Book';
        }
        return null; // GraphQLError is thrown
    }
  },
  Query: {
    search: () => {...}
  }
}
```

#### Interface

複数のオブジェクトで実装される値の集合を定義する  
戻り値に指定することで、少なくともそのフィールドは実装されていることが保証される  
Unionと同じようにクエリとリゾルバに対応する必要がある

```graphql
interface Book {
  title: String!
  author: Author!
}

type Textbook implements Book {
  title: String! # must implemented
  author: Author! # must implemented
  courses: [Course!]!
}

type Query {
  books: [Book!]!
}
```

#### docstring

```graphql
"Description for the type"
type MyObjectType {
  """
  Description for field
  Supports **multi-line** description for your [API](http://example.com)!
  """
  myField: String!

  otherField(
    "Description for argument"
    arg: Int
  )
}
```

### resolverについて

- リゾルバが定義されていない場合はapolloはデフォルトリゾルバを使う。
- 全てのリゾルバを一つのjavascriptオブジェクトにまとめることになり、このオブジェクトのことをresolver mapと呼ぶ
- resolver mapはスキーマタイプに該当するトップレベルフィールドを持つ。
- 全てのリゾルバ関数はいづれかのスキーマタイプに関連付けられる。
- リゾルバは4つの引数を持つ
  - `parent`: 親のリゾルバの戻り値
  - `args`: クエリの引数
  - `context`: リゾルバ間で共有されるオブジェクト、認証情報やデータローダのインスタンスなどを格納するのに使う
  - `info`: GraphQLの実行状態を表すオブジェクト[主要フィールドはここで見れる](https://github.com/graphql/graphql-js/blob/f851eba93167b04d6be1373ff27927b16352e202/src/type/definition.ts#L891-L902)
    - apollo serverではcacheControlフィールドを拡張している
- [デフォルトリゾルバ](https://www.apollographql.com/docs/apollo-server/data/resolvers#default-resolvers)

```typescript
const resolvers = {
  Query: {
    user(parent, args, contextValue, info){
      return users.find((user) => user.id === args.id);
    },
  },
};
```

#### ContextとcontextValue

- context関数を登録でき、その戻り値は全てのリゾルバで共有される。  
- context関数はリクエストごとに実行されるので、リクエストごとに異なる値を持つことができる。  
- context関数に渡される引数は使用するフレームワークによって異なる。
- context関数は非同期なので、DBコネクションの取得などを待つことができる。
- 通常だとcontext関数でエラーが発生した場合には500エラーが返されるが、`GraphQLError`をthrowすることで、任意のエラーを返すことができる。
- プラグインも[ライフサイクル関数](https://www.apollographql.com/docs/apollo-server/integrations/plugins#responding-to-request-lifecycle-events)をを使用してcontextValueにアクセスすることができる。
- [エラーハンドリング](https://www.apollographql.com/docs/apollo-server/data/errors)

```typescript
import { GraphQLError } from 'graphql';

const resolvers = {
  Query: {
    // Example resolver
    adminExample: (parent, args, contextValue, info) => {
      if (contextValue.authScope !== ADMIN) {
        throw new GraphQLError('not admin!', {
          extensions: { code: 'UNAUTHENTICATED' },
        });
      }
    },
  },
};

interface MyContext {
// You can optionally create a TS interface to set up types
// for your contextValue
  authScope?: String;
}

const server = new ApolloServer<MyContext>({
  typeDefs,
  resolvers,
});

const { url } = await startStandaloneServer(server, {
  // Your async context function should async and
  // return an object
  // highlight-start
  context: async ({ req, res }) => ({
    authScope: getScope(req.headers.authorization),
  }),
  // highlight-end
});
```

### DataSourceについて

- お手本[RestDataSource](https://github.com/apollographql/datasource-rest/blob/main/src/RESTDataSource.ts)
- [DataLoader](https://github.com/graphql/dataloader)が強くおすすめされている
- DataLoaderはキャッシュができるのと、リクエストのバッチ化が可能
- DataLoaderのインスタンスはリクエストごとに作ること
- なんかトップレベルawaitのやり方があるっぽい。Getting Startに書いてある？
- dataSourceはcontext関数に追加する

### AWS Lambdaへのデプロイ

lambdaに実装する専用のライブラリがある。  
https://github.com/apollo-server-integrations/apollo-server-integration-aws-lambda  
コンテキストの渡し方が違う! mainブランチのREADMEに書いてある方が正しい

ミドルウェアを設定できるので、認証などを自由に設定することが可能

lambdaにデプロイして、apigatewayでそのlambdaへの統合を作ればOK。パスとかはなんでもいい感じ

