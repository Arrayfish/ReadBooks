# Rust　atcoder

## 参考資料
[AtCoderコンテストにRustで参加するためのガイドブック](https://doc.rust-jp.rs/atcoder-rust-resources/introduction.html)

[Atcoderの新しいRustのバージョンに対応したテンプレート](https://github.com/rust-lang-ja/atcoder-proposal/)

## 環境構築

新しいテンプレートを`cargo generate --git https://github.com/rust-lang-ja/atcoder-proposal`で持ってくる

## NOTE

cargo-competeという名前のcliアプリがある。これも2014の古いバージョンがある。

## 使用するクレートについて

## 入力の受け取り方

proconioクレートを使用する  

```rust
use proconio::input;

input!{
    n: u8,
    mut m: u32,
    h: usize,
    w: usize,
    a: [[i32; w], h] // `a` is Vec<Vec<i32>>, (h, w)-matrix
}

println!!("{},{},{}", n, m, l)
```

配列の最初の一つがそれ以降の配列の配列数を表すような配列を扱う場合、配列数を省略できる。  

```rust
use proconio::input;

input!{
    n: usize,
    a: [[i32]; n],
}

// 入力が次の場合の結果 "3  3 1 2 3  0  2 1 2"
assert_eq!(
    a,
    vec![
        vec![1, 2, 3],
        vec![],
        vec![1, 2],
    ]
);
```

文字列は`Vec<u8>`と`Vec<char>`でも読み取り可能

```rust
use proconio::input;
use proconio::marker::{Byte, Chars};

input!{
    string: String, // read as String 
    chars: Chars,   // read as Vec<char>
    bytes: Bytes,   // read as Vec<u8>
}

assert_eq!(string, "string");
assert_eq!(chars, ['c', 'h', 'a', 'r', 's'])
assert_eq!(bytes, b"bytes")
```

## rustの標準ライブラリ

### abs

`<number>.abs()`

### sin/cos/tan

`<float>.sin(); <float>.cos(); <float>.tan();`

### max/min

2値の比較

```rust
use std::cmp;

assert_eq!(cmp::min(1,2), 1);
assert_eq!(cmp::max(1,2), 2);
```

配列から取り出す場合はイテレータを取り出して`max()`関数を使用する  
この時、戻り値が`Option`型になっていることに注意

```rust
let nums: Vec<i32> = vec![3,1,5,4,2];

if let Some(max) = nums.iter().max(){
    println!("Max value: {}", max);
} else {
    println!("nums is empty");
}
```

### swap

```rust
// 標準ライブラリのswap
let mut a = 3, b = 5;
std::mem::swap(&mut a, &mut b);
assert_eq!(a, 5);
assert_eq!(b, 3);
```

標準ライブラリのswapでは2次元配列の要素同士のswapなどはできない。  
何かsnippetを作成する必要性がありそう。  
参考: https://qiita.com/tanakh/items/d70561f038a0ef4f0ff1
