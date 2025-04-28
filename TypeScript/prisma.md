# [Prisma](https://www.prisma.io/docs)

Typescriptで一番有名なORM

prisma engineとprisma clientがあり、prisma clientがprismaのクエリを受け取り、prisma engineがデータベースにクエリを投げる。

`npx prisma generate`でprisma clientを生成する。  
prismaでマイグレーションを行うと自動的にprisma clientが生成される。  
デフォルトでは`node_modules/.prisma/client`に生成されるが、`prisma.schema`の`generator client`で変更できる。

`npx prisma db pull`で既存のDBから`prisma.schema`を取得する

[Prismaをaws lambdaにデプロイするときの注意点](https://www.prisma.io/docs/orm/prisma-client/deployment/serverless/deploy-to-aws-lambda#binary-targets-in-schemaprisma)

スキーマなどに命名規則みたいなものがあるらしい

## コネクション設定

サーバレス環境と一般的な長期接続とで推奨される設定が違う

### 一般的な長期接続

- コネクションプール数をデフォルト(cpuコア数*2+1)にすること、インスタンス数が複数ある場合はその数で割った数を指定すること
- 一つの`PrismaClient`インスタンスをアプリケーション全体で使いまわすこと、一つのファイルでインスタンス化してexport defaultすること
- 明示的に`$disconnect()`を呼ばないこと
- Next.jsなどでは、PrismaClientをグローバルにしてhot reloadのたびにインスタンス化されないようにすること

### サーバレス環境

- 外部コネクションプールを使わないならコネクションプールの数`connection_limit`を1にすること
- コネクション数が多い場合は外部のコネクションプールを使うこと(awsならRDS Proxy)
- `connection_limit`が1の場合は並列でリクエストを飛ばさないこと
- `PrismaClient`のインスタンスをハンドラの外側で作成すること
- 明示的に`$disconnect()`を呼ばないこと


## Prisma Clientの使い方

### Create

```typescript
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main(){
  await prisma.user.create({
    data: {
      name: "Alice", 
      email : "Alice@example.com",
      posts: {
        create: {  title: "Hello world"},
      },
      profile: {
        create: { bio: "I love turtles"},
      }
    }
  });
}
main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect()
    process.exit(1);
})
```

### Select

```typescript
// 省略
const allUsers = await prisma.user.findMany({
  include: {
    posts: true, 
    profile: true,
  }
})
```

### update

```typescript
// 省略
const post = await prisma.post.update({
  where: { id: 1 },
  data: {published: true},
})
```
