# Amazon Congnitoについてのメモ

BMCで使用されている部分付近をつまむ

[Amazon Cognito Developer Guide](https://docs.aws.amazon.com/ja_jp/cognito/latest/developerguide/what-is-amazon-cognito.html)
のまとめ

ここまで読んだ
https://docs.aws.amazon.com/ja_jp/cognito/latest/developerguide/cognito-console.html

Amazon Cognitoはユーザプールとアイデンティティプールで構成される

## ユーザプール

### 使用目的
アプリケーションまたはAPIのユーザを認証および承認する場合はユーザプールを作成する。
### 機能概要
セルフサービスと管理者主導の両方によるユーザ作成、管理、認証を行うユーザディレクトリ
他のIDプロバイダが管理しているユーザIDも取り込める。

ユーザープールはアイデンティティプールとの統合を必要としません。ユーザープールから、認証された JSON ウェブトークン (JWT) をアプリ、ウェブサーバー、または API に直接発行できます。

## アイデンティティプール

### 使用目的
認証されたユーザーまたは匿名ユーザーに AWS リソースへのアクセスを許可する場合は、Amazon Cognito アイデンティティプールを設定します。

### 機能概要
アイデンティティプールは、ユーザにリソースを提供するためのアプリ用のAWS認証情報を発行する。  
ユーザプールやSAML 2.0など、信頼できるIDプロバイダでユーザを認証可能。  
オプションでゲストユーザに認証情報を発行することも可能。  
アイデンティティプールは、ロールベースと属性ベースのアクセス制御の両方を使用して、AWSリソースへのアクセスに対するユーザ権限を管理する

アイデンティティプールはユーザープールとの統合を必要としません。アイデンティティプールは、ワークフォースとコンシューマーの両方の ID プロバイダーからの認証済みクレームを直接受け入れることができます。

## 自分なりのまとめ

ユーザプールは1ユーザに対するユーザIDを管理する
アイデンティティプールはユーザIDに対してAWSリソースの認証を管理する
