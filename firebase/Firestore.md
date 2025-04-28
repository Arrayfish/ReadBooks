# [Filestore](https://firebase.google.com/docs/firestore?hl=ja)

同じような機能にRealtime databaseがあるが、FirestoreはNoSQLのデータベースで、より複雑なクエリやデータ構造をサポートしている。  
Firestoreは、Firebaseの一部であり、Google Cloud Platform上で動作するNoSQLデータベースサービスです。Firestoreは、リアルタイムデータ同期、オフラインサポート、スケーラビリティ、セキュリティルールなどの機能を提供します。Firestoreは、ドキュメント指向のデータベースであり、データはコレクションとドキュメントの形式で保存されます。

## データモデル

ドキュメントはレコクションに保存される。
一連のkey-valueのペアーをドキュメントとして保存する。  
ドキュメントには、サブコレクションとネストされたドキュメントを持つことができる。

交互にコレクションとドキュメントにアクセスして階層付けられたデータにアクセスする。

### ドキュメント

ドキュメントの名前が必要
内部にkey-valueの値を持つことができる。
set()メソッドを利用して、ドキュメントの値を設定。上書き。mergeオプションで、部分的に追加も可能
update()メソッドを利用して、ドキュメントの値を変更可能。配列を変更するときは、arrayUnion(), arrayRemove()メソッドを使用できる。
update()メソッドで特定のkey-valueのみを削除する場合は、`update({"key": firestore.DELETE_FIELD})`を使用します。
ドキュメント全体を削除するときはdelete()メソッドを使用する。