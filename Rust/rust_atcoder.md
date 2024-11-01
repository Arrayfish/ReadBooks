# Rust　atcoder

## 参考資料
[AtCoderコンテストにRustで参加するためのガイドブック](https://doc.rust-jp.rs/atcoder-rust-resources/introduction.html)

[Atcoderの新しいRustのバージョンに対応したテンプレート](https://github.com/rust-lang-ja/atcoder-proposal/)

## 環境構築

新しいテンプレートを`cargo generate --git https://github.com/rust-lang-ja/atcoder-proposal`で持ってくる

## NOTE

cargo-competeという名前のcliアプリがある。これも2014の古いバージョンがある。

## 使用するクレートについて

## [チートシート](https://zenn.dev/tipstar0125/articles/898cd37c76dce8)

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

### gcd(最大公約数)

```rust
use num::integer::{gcd, lcm};

assert_eq!(gcd(18, 30), 6);
assert_eq!(lcm(18, 30), 90);
```

### rand

```rust
use rand::prelude::*;
// 簡単なランダム関数　変数の型によって値が変化する
let x: u8 = random();
let y: i32 = random();
// Thread local generator
let mut rng = thread_rng();
lex x: f64 = rng.gen(); // [0, 1)
let y = rng.gen_range(-10.0..10.0)

let directions = "news".chars();
println!("lets got in this direction": {}, directions.choose(&mut rng).unwrap());
let mut nums = [1,2,3,4,5];
nums.shuffle(&mut rng);
println!("Shuffled nums {:?}", nums);
```

### sort

```rust
// 昇順、降順
let mut A = vec![3,1,2]
A.sort(); // 昇順
A.reverse(); // 降順
// キーを指定したソート
let mut A = vec![(1,3), (2,1), (3,2)];
A.sort_by(|(_, a), (_, b)| b.cmp(a)) // 第2要素で降順
let mut B = vec![("a", 90, 80), ("d", 70, 80), ("c", 90, 60), ("b", 70, 80)];
B.sort_by(|(a0, a1, a2), (b0, b1, b2)| (-a1, a2, a0).cmp(&(-b1, b2, b0)));
// 第2要素で降順、第3要素で昇順、題1要素で昇順の優先度で並べ替え
```

### hashmap

```rust
use std::collections::HashMap;

let mut scores = HashMap::new();

scores.insert(String::from("Blue"), 10);
scores.insert(String::from("Yellow"), 50);
scores.insert(String::from("Yellow"), 30); // 上書き
scores.entry(String::from("Blue")).or_insert(200) // キーが存在しない場合に挿入

let team_name = String::from("Blue")
let score = scores.get(&team_name);
assert_eq!(score, Some(&10));

let mut map = HashMap::new();

for word in text.aplit_whitespace(){ // 単語数をカウントする
    let count = map.entry(word).or_insert(0);
    *count += 1;
}
```

### reverse

```rust
// reverse
let mut v = vec![1,2,3,4,5];
v.reverse();
assert_eq!(v, [5,4,3,2,1])
```

### deque

```rust
use std::collections::VecDeque;

let mut que = VecDeque::new();

que.push_back(0);
que.push_back(1);
que.push_back(2);
println!("{:?}", que); // [0, 1, 2]

println!("{:?}", que.pop_front()); // Some(0)
println!("{:?}", que); // [1, 2]

que.pop_front(); que.pop_front();
println!("{:?}", que.pop_front()); // None
```

### priority queue

```rust
use std::collections::BinaryHeep;

let mut pque = BinaryHeap::new();

pque.push(0);
pque.push(2);
pque.push(1);

println!("{:?}", pque.pop()); // Some(2)
println!("{:?}", pque.pop()): // Some(1)
pque.push(3);
println!("{:?}", pque.pop()): // Some(3)
println!("{:?}", pque.pop()): // Some(0)
println!("{:?}", pque.pop()): // None
```
