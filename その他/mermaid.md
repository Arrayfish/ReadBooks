# [Mermaid記法](https://mermaid.js.org/)

コードで図を表現できる記法  
GitHubがデフォルトで採用しているので、README.mdなどに使用できる

## 表現可能な図

- フローチャート図
- シークエンス図
- クラス図
- 状態遷移図
- ER図
など

### ER図

サンプル

``` mermaid
---
title: Example Title
---
erDiagram
    CUSTOMER ||--o{ ORDER : places
    CUSTOMER {
        string name
        string custNumber
        string sector
    }
    ORDER ||--|{ LINE-ITEM : contains
    ORDER {
        int orderNumber
        string deliveryAddress
    }
    LINE-ITEM {
        string productCode
        int quantity
        float pricePerUnit
    }
```

#### カーディナリティ

- `|o`: 1か0
- `||`: 1
- `}o`: 0以上
- `}|`: 1以上

```mermaid
erDiagram
    Some |o--o| Another: "1 or 0"
    Some ||--|| Another: "1"
    Some }o--o{ Another: "> 0"
    Some }|--|{ Another: "> 1"

```

## vscode拡張機能

- Markdown Preview Mermaid Support: Markdownのプレビューで表示するためのもの
- Mermaid Markdown Syntax Highlighting: シンタックスハイライト用
