# Axum

最近はactix-webよりかはこちらがデファクトスタンダードになりつつある

## [axum-login](https://docs.rs/axum-login/latest/axum_login/index.html)

ログインを実装するミドルウェア

tower-sessionというクレートを使ってセッション情報を保存するバックエンドを実装する。
割と認証方法とかを実装する必要がありそう

AuthUserとAuthnBackendの2つのトレイトを実装する必要がある。

AuthzBackendトレイトを実装することで、ユーザ単位や、グループ単位でのアクセス制御を実装できる。

login_requiredやpermission_requiredマクロを使って、ログインが必要なページや、権限が必要なページを実装できる。



