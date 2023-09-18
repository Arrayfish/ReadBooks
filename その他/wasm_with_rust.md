rustでwasmのプロジェクトを作るときにどうも３種類のテンプレートがあるらしい。

- create-wasm-app
- wasm-pack-template
- rust-webpack-template
## create-wasm-app
`npm init wasm-app <project-name>`で実行される。  
このテンプレートは、Rustで生成されたWebAssemblyを含むNPMパッケージに依存し、それらを使用してウェブサイトを作成するために設計されています。
Webpackを使用してRustで生成されたWebAssemblyをバンドルするプロジェクトを作成するためのnpmテンプレートです。
Rustで生成されたWebAssemblyをnpmパッケージに含め、Webpackでバンドルするプロジェクトを作成するためのものです。
rustのコードは書かれていない。
チュートリアルではwasm-packで作成したプロジェクトの内部でこのテンプレートでプロジェクトを作成していた。
## wasm-pack-template
`cargo generate --git https://github.com/rustwasm/wasm-pack-template`で実行される
RustライブラリをWebAssemblyにコンパイルし、生成されたパッケージをnpmに公開するためのテンプレートです。
WebAssemblyにコンパイルしてnpmパッケージとして公開できるRustライブラリを作成するために設計されています。

viteとかで使うときはそのプロジェクトの中でこれを実行すればrustのコードからwasmをビルド出来る。
## rust-webpack-template
Rustで生成されたWebAssemblyとWebpackを使ってmonorepoスタイルのWebアプリケーションを作成するためのテンプレートです。
Rustで生成したWebAssemblyとWebpackを使ってWebアプリケーションを作成するプロジェクトを作成するためのものです。 
最初からrustのコードが含まれている

これだと最初からrustのコードとjavascriptのコードが含まれている。  
wasm-packのチュートリアルで使った。  
`npm init rust-webpack <project-name>`で実行される。