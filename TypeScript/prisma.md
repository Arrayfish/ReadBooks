# [Prisma](https://www.prisma.io/docs)

Typescriptで一番有名なORM

prisma engineとprisma clientがあり、prisma clientがprismaのクエリを受け取り、prisma engineがデータベースにクエリを投げる。

`npx prisma generate`でprisma clientを生成する。  
prismaでマイグレーションを行うと自動的にprisma clientが生成される。  
デフォルトでは`node_modules/.prisma/client`に生成されるが、`prisma.schema`の`generator client`で変更できる。

`npx prisma db pull`で既存のDBから`prisma.schema`を取得する

[Prismaをaws lambdaにデプロイするときの注意点](https://www.prisma.io/docs/orm/prisma-client/deployment/serverless/deploy-to-aws-lambda#binary-targets-in-schemaprisma)

スキーマなどに命名規則みたいなものがあるらしい

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
