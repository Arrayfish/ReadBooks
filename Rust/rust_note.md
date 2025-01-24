# rustそのものの使用についてのメモ

## 

## module

一般的にはクレートとして使うために下記のルートファイルでモジュールを宣言する
- src/main.rs
- src/lib.rs
ルートファイルではmodキーワードでの宣言が必要
この時にファイル名がモジュール名になる。

別のファイルの関数などにはモジュールとしてアクセス可能  
pubで公開されている必要がある  
使う関数などが入っているファイルを`mod`でファイルの上部で宣言する。  
ファイルと同じ名前のディレクトリ内のファイルで公開された関数などを自分のモジュールとして再配布することができる。  
その場合は同じ名前のディレクトリ内のファイル名をファイルの上部で`pub mod <filename>`と書く

modキーワードはモジュールの宣言や、使用するモジュールを宣言するときに使う。  
useキーワードはモジュールのパスを短縮するだけ。

ファイルの分割でモジュールを分割するのがベター。ファイル内分割も可能。

参考URL
- [Rustのmodule完全に理解した。](https://zenn.dev/newgyu/articles/3b4677b4086768)
- [[Rust] モジュールのベストプラクティス](https://zenn.dev/msakuta/articles/83f9991b2aba62#re-export)

## [workspace](https://doc.rust-lang.org/cargo/reference/workspaces.html)

子ディレクトリを一つのパッケージとして扱うことができる。  
一つのモジュールを複数の場所？から参照するときに使用する。  
親ワークスペースのCargo.tomlに[workspace]を追加することによって使用可能

この場合は子ワークスペースに[package]を追加する必要がある。

## Arc, Rc

Rcはいわゆるスマートポインタ  

Arcは異なるスレッド間で使用することができるバージョン  
Arcを使って可変な値の参照をとる場合はMutex<>で排他制御にする必要がある

## ReCellとRcを使用した再帰のコード

## enum

名前なしのStructを作成する場合のみは{}を使用する。
それ以外は()の中に型を追加する

```
enum Message {
    Resize{width: u64, height: u64},
    Move(Point),
    Echo(String),
    ChangeColor(u8, u8, u8),
    Quit
}

```

## trait

構造体でtraitによって定義された関数を実行する場合は、その構造体に加えてtrait自体もスコープに入れる必要がある。  

```rust
// speak_person.rs
pub trait Speak {
    fn hello(&self) -> String;
}

pub struct Person {
    pub name: String,
}

impl Speak for Person {
    fn hello(&self) -> String {
        format!("Hello, I'm {}", self.name)
    }
}

// another file
mod speak_person;
use speak_person::Person;
use speak_person::Speak;

fn main() {
    let person = Person{name: "Alice".into()};
    println!("{}",person.hello());
}
// Hello, I'm Alice
```

## String

.to_string()とString::from()は同じ
to_owned()は&strからStringを作成する。
&strが.into()をするとStringになる。

基本的には&strが固定値のスライスなので、値や所有者が変わる処理をするとStringになる。

### 文字列の追加

- format!()
- +=で連結
- push_str()

### イテレータ

イテレータに対して.as_str()を使用することで、残りの文字をstrに変換できる。
match char = chars.next(){
    Some(char) => char.to_uppercase.to_string() + chars.as_str()
    None => String::new()
}

#### collect()

collect関数では戻り値の型によって最適な形に変換してくれる。