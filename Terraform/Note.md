# HCL の文法

## プロバイダの設定

### aws の場合

```hcl
provider "aws" {
    region = "us-east-2"
}
```

## リソースの記述方法

リソース: サーバ、DB、LB など　プロバイダタイプによる

### 基本の文法

```hcl
resource "<プロバイダ>_<タイプ>" "<名前>" {
    [設定 ...]
}
```

### aws の EC2 インスタンスの場合

```
resource "aws_instance" "example" {
    ami = "ami-......."
    instance_type = "t2.micro"
}
```

## リソースの参照

`<PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>`

セキュリティグループの例: `asw_security_group.instance.id`

## 入力変数

```hcl
variable "NAME" {
    [CONFIG ...]
}
```

CONFIG 部分で使用するパラメータ

- description: 説明
- default: 変数のデフォルト値。この場所での定義は優先度が低め？
- type: 型　 e.g.)sting, number, bool, etc...
- validation: 最大値、最小値など
- sensitive: true の場合に値をログに残さない。機密情報向け

例

```hcl
variable "number_example" {
    description = "An example of a number variable in Terraform"
    type = number
    default = 42
}

variable "list_numeric_example" {
    description = "An example of a numeric list in Terraform"
    type = list(number)
    default = [1, 2, 3]
}
```

object 型制約を使用して、さらに複雑な構造体型を作成可能

```hcl
variable "object_example_with_error"{
    description = "An example"
    type = object({
      name = string
      age = number
      tags = list(string)
      enabled = bool
    })

    default = {
        name = "value1"
        age = 42
        tags = ["a", "b", "c"]
        enabled = "invalid"
    }
}
```

### 補完

文字列リテラルの中で変数を参照する式  
スクリプトの中などで、変数の値を使用する場合に使用する

`"${...}"

## 出力変数

`terraform apply`を実行した後にコンソールに情報を出力できる。  
terraform をスクリプトで使用する場合に便利

### 文法

```hcl
output "<NAME:変数名>" {
    value = <VALUE:出力するTerraform式>
    [CONFIG ...]
}
```

### CONFIG がとる値

- description: 説明
- sensitive: 同上。式に使用している入力変数が sensitive などの場合は出力変数も true にするべき
- depends_on: 稀に、明示的に依存関係を示すことが必要。

### 例

```
output "public_ip"{
    value = aws_instance.example.public_ip
    description = "The public IP address of the web server"
}
```

## ライフサイクルの設定

各 Terraform リソースがどのように作成、更新、削除されるかを制御するための設定

### 例

```hcl
resource "aws_instance" "example" {
    ami = "ami-......."
    instance_type = "t2.micro"

    lifecycle {
        create_before_destroy = true
    }
}
```

## データソース

Terraform を動かすたびにプロバイダ(ここでは AWS)から取得する、読み出し専用の情報

### 文法

リソースの文法とよく似ている

```hcl
data "<PROVIDER>_<TYPE>" "<NAME>" {
    [CONFIG ...]
}
```

### 例

```hcl
data "aws_vpc" "default"{
    default = true
}
```

#### 読み方

`aws_vpc.default.id`

## ステート管理

Terraform は構築したインフラの情報を Terraform ステートファイルに保存する  
`terraform plan`コマンドの出力はこのステートファイルと、コードの差分である  
複数人で開発を行う時は、Terraform のリモートバックエンド機能を使用してステートファイルをクラウドなどに保存する。

### 文法

```hcl
teraform{
    backend "<BACKEND_NAME>" {
        [CONFIG...]
    }
}
```

### 例

````hcl
terraform {
    backend "s3" {
        bucket = "terraform-up-and-running-state"
        key="global/s3/terraform.tfstate"
        region='ap-northeast-1'
        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}

### リモートバックエンド

最初にバックエンド用のs3とdynamoをローカルバックエンドで作成し、その後にリモートバックエンドにコピーする
各アカウントに1回でOKで次回は作成する必要がない。

backendブロックでは変数や参照を使用することができない。
部分設定という仕組みを使用する
backend.hclファイルに共通の設定を記述し、それを参照する
`terraform init -backend-config=backend.hcl`

### ワークスペース機能

`terraform workspace`コマンドを使用して、環境を分離できる。
簡単な実験に便利
同じ認証を使用しなければならなかったり、workspaceを間違えやすいので、本番環境では使用しない方が良い

### ファイルレイアウトによる分離

各環境用のterraformファイルを環境ごとのディレクトリに分けて管理する
よく使われるのは以下のようなディレクトリ
- stage: ステージング
- prod: 本番
- mgmt: DevOps用のリソース(踏み台, CI/CD サーバなど)
- global: 全環境を跨ぐリソース(S3, IAM, etc...)
それぞれの環境でさらにコンポーネントごとにディレクトリを分割する
よく使用されるのはは以下のようなディレクトリ
- vpc: ネットワークトポロジ
- service: アプリケーション　さらにその中でバックエンドとフロントエンドとか
- data-strage: DB、cacheなど
各ファイルの中で次のように設定ファイルを分類する
- variables.tf: 入力変数
- outputs.tf: 出力変数
- main.tf: リソースとデータソース


## terraform_remote_stateデータソース
別のTerraform設定で保存されているTerraformステートを読み出すためのもの

### 文法

```hcl
data "terraform_remote_state" "<NAME>" {
    backend = "s3"

    config = {
        bucket = "<BUCKEND_BUCKET_NAME>"
        key = "<BUCKEND_KEY_NAME>"
        region = "<REGION>"
    }
}

resource "<SOME>" "<SOME>" {
    some = data.terraform_remote_state.<NAME>.outputs.<ATTR>
}
````

## ビルドイン関数

format(), templatefile()などいろいろな種類がある。  
`terraform console`でコンソールを開いて試せる。

### 文法

main.tf がおいてあるディレクトリを外部から参照することで、モジュールとして使用される。

```hcl
function_name(...)
```

## モジュール

### 文法

```hcl
module "<NAME>" {
    source = "<SOURCE>"

    [CONFIG ...]
}
```

NAME: モジュールの識別子  
SOURCE: モジュールのコードのパス  
CONFIG: モジュール固有の引数

### 例

```hcl

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name = "webservers-stage"
    db_remote_state_bucket = "uekusa-terraform-up-and-running-state"
    db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"

    instance_type = "t2.micro"
    min_size = 2
    max_size = 10
}
```

### ローカルな値を作成する

共通化したいが、モジュール外部には公開したくない場合に使用する

```hcl
locals {
    <KYE> = <VALUE>
    ...
}

some = local.<KEY>
```

### モジュールのアウトプット

outputs.tf の書き方はリソースのと同じ。

リソースの中では

```hcl
module.<MODULE_NAME>.<OUTPUT_NAME>
```

のように参照する。

### パス参照

基本的には terraform ではカレントディレクトリからのパスと判断される。  
モジュールでファイルパスがうまく指定できるようにパス参照を使用する。

- path.module: 定義があるモジュールが存在するファイルシステムパス
- path.root: ルートモジュールのファイルシステムパス
- path.cwd: カレントディレクトリのファイルシステムパス。基本的には path.root と同じ。

### インラインブロック

Terraform のリソースの中でインラインブロックとしてもかけるし、別のリソースとしてもかけるものがある。  
インラインブロックと別リソースの両方を混ぜて使用すると設定がコンフリクトして問題を起こす。  
おすすめは常に別リソースを使用すること

#### 例

resource "xxx" "yyy" {
<inline_block> {
zzzzzzz
}
}

### モジュールのバージョン管理

モジュールの source パラメータにはローカルファイルパス以外にも git の URL なども入れることができる。  
バージョン管理をする一番簡単な方法はモジュールのコードを別々の Git リポジトリに入れて、source パラメータをリポジトリの URL にすること  
この場合は Terraform のコードが少なくとも 2 つのリポジトリに分散される.

- modules: 再利用可能なモジュールを定義する
- live: 各環境(stage, prod, mgmt など)で実際に動作するインフラを定義する

開発中の場合はローカルファイルパスの方が楽で良い

## Terraform を使用するためのヒントとコツ

### ループ

- count パラメータ: リソースに対してループする
- for_each 式: リソースやリソース内のインラインブロックに対してループする
- for 式: リストやマップに対してループする
- for 文字列命令: 文字列内のリストやマップに対してループする

#### count パラメータ

##### 例

```hcl
resource "aws_iam_user" "example" {
    count = length(var.user_names)
    name = var.user_names[count.index]
}
```

##### デメリット

- インラインブロックが考慮されない。
- リストの途中を削除などの変更をしてしまうと、それ以降のリストが全て変わってしまう。

#### for_each 式

COLLECTION に対して`each.key`でキー、`each.value`で値をとれる

##### 文法

```hcl
resource "<PROVIDER>_<TYPE>" "<NAME>" {
    for_each = <COLLECTION>

    [CONFIG ...]
}
```

インラインブロックに対しても適用できる

##### 文法

```hcl
dynamic "<VAR_NAME>" {
    for_each = <COLLECTION>

    content {
        [CONFIG...]
    }
}
```

##### 例

```hcl
dynamic "tag" {
    for_each_var.custom_tags

    content {
        key = tag.key
        value = tag.value
    }
}
```

ここで、key, value はそれぞれ custom_tags のキーと value になる。

#### for 式

##### 文法

```hcl
[for <ITEM> in <LIST> : <OUTPUT>]
# マップ
[for <KEY>, <VALUE> in <MAP> : <OUTPUT>]
# 集合を出力する場合
## リストに対するループ
[for <ITEM> in <LIST> : <OUTPUT_KEY> => <OUTPUT_VALUE>]
## マップに対するループ
[for <KEY>, <VALUE> in <MAP> : <OUTPUT_KEY> => <OUTPUT_VALUE>]
```

##### 例

```hcl
variable "names" {
    description = "A list of names"
    type = list(string)
    default = ["nero", "trinity", "norpheus"]
}

# 条件をつけて結果のフィルタも可能
output "upper_names" {
    value = [for name in var.names : upper(name) < 5]
}

# mapのfor文
variable "hero_thousand_faces" {
    description = "map"
    type = map(string)
    default = {
        neo = "hero"
        trinity = "love interest"
        morpheus = "mentor"
    }
}

output "bias" {
    value = [for name, role in var.hero_thousand_faces: "${name} is the ${role}."]
}
```

#### for の文字列ディレクティブを使用したループ

文字列ディレクティブ: `%{...}`の記号を使用して文字列内で制御構文(for ループや if 文など)を使用することができる。

##### 文法

```hcl
%{ for <ITEM> in <COLLECTION> }<BODY>%{ endfor }
# インデックスを使用した例
%{ for <INDEX>, <ITEM> in <COLLECTION> }<BODY>%{ endfor }
```

##### 例

```hcl
variable "names" {
    description = "A list of names"
    type = list(string)
    default = ["nero", "trinity", "norpheus"]
}

output "for_directive"{
    value = "%{ for name in var.names }${name}, %{ endfor }"
}
# Outputs:
# for_directive = "neo, trinity, morpheus, "

# インデックスを使用した例
output "for_directive_index" {
    value = "%{ for i, name in var.names }(${i}) ${name}, %{ endfor }"
}
# Outputs:
# for_directive_index = "(0) neo, (1) trinity, (2) morpheus, "

```

### 全てのリソースに tag をつける方法

各モジュールの default_tags ブロックを設定する

```hcl
provider "aws" {
    region = "ap-northeast-1"

    default_tags {
        tags = {
            Owner = "team-foo"
            ManagedBy = "Terraform"
        }
    }
}
```

### 条件分岐

- count パラメータ: 条件付きリソースに使用
- for_each 文と for 文: 条件付きのリソースまたは、リソース内のインラインブロック
- if 文字列ディレクティブ: 文字列内の分岐

count と for_each の使い分けは、単純に条件付きで生成したい場合は count。それ以外は for_each

#### count パラメータを使用した条件分岐

`count = 0`の時にリソースが生成されないことを利用する。  
terraform の条件式`<CONDITION> ? <TRUE_VAL> : <FALSE_VAL>`も利用する

##### 例

```hcl
variable "enable_autoscaling" {
    description = "If set to true, enable auto scaling"
    type = bool
}

resource "aws_something" "example" {
    count = var.enable_autoscaling ? 1 : 0
}
```

#### count パラメータによる if-else 文

##### 例

```hcl
variable "ifelse_val" {
    type = bool
}

resource "aws_something" "if_example" {
    count = var.ifelse_val ? 1 : 0
}
resource "aws_something" "else_example"{
    count = var.ifelse_val ? 0 : 1
}
```

##### if-else 文を使用した時の出力

###### いまいちなアプローチ

```hcl
output "aws_something_arn" {
    value = {
        var.ifelse_val
        ? aws_something.if_example[0].arn
        : aws_something.else_example[0].arn
    }
}
```

###### 安全なアプローチ

- concat 関数: 2 つ以上のリストを引数に取り、1 つのリストを返す
- one 関数: 引数として 1 つのリストをとり、要素数が 0 なら null を、1 ならその要素を、複数ならエラーを返す

```hcl
output "aws_something_arn" {
    value = one(concat(
        aws_something.if_example[*].arn,
        aws_something.else_example[*].arn
    ))
}
```

#### for_each と for を使用した条件分岐

count とほとんど同じ、for_each や for に空の集合を与えると、リソースを生成しない。

```hcl
dynamic "tag" {
    for_each = {
        for key, value in var.custom_tags:
        key => upper(value)
        if key != "Name"
    }

    content {
        key = tag.key
        value = tag.value
        propagate_at_launch = true
    }
}
```

#### if 文字列ディレクティブを使用した条件分岐

##### 文法

```hcl
%{ if <CONDITION> }<TRUEVAL>%{ endif }
%{ if <CONDITION> }<TRUEVAL>%{ else }<FALSEVAL>%{ endif }
```

- <CONDITIONS>: 論理値を返す式
- <TRUEVAL>: <CONDITIONS>が true になった時にレンダリングされる式
- <FALSEVAL>: ...false...

##### 例

ループで最後の要素だけ後ろにコンマと空白をつけない例  
チルダ~を使用することで、文字列ディレクティブに追加するとチルダの前後のスペースが削除される。

```hcl
output "for_directive_index_if" {
    value = <<EOF
%{~ for i, name in var.names ~}
  ${name}%{ if i < length(var.names) - 1 }, %{ else }.%{ endif }
%{~ endfor ~}
EOF
}
```

### ゼロダウンタイムデプロイ

EC2 の起動テンプレートなど、変更してもすぐに実際のサーバに反映されない場合がある。  
この場合には

1. create_before_destroy ライフサイクルを設定する
2. ASG の name パラメータが起動テンプレートの名前を直接参照するようにして、起動テンプレートが置き換わる時に ASG も置き換わるようにする。
3. ASG の min_elb_capacity パラメータをクラスタの min_size に設定する。
   下の ASG を削除するあえに、置き換え先の ASG で最低でも指定した数のサーバがヘルスチェックをパスするまで待つようになる。

実際には起動テンプレートだと、名前が変わらなかったので、バージョンを ASG の名前に追加した。

### Terraform のつまずきポイント

#### count と for_each の制限

ハードコートされる値は参照できるが、計算結果となるリソースの出力は参照ができない。

#### ゼロダウンタイムデプロイの制限

Auto Scaling のポリシーとは共存できない。途中でサーバ台数を増やしてりしても、初期値に戻ってしまう。  
ゼロダウンタイムデプロイのような複雑なタスクには上でやったような方法より、ネイティブでサポートされた方法を使うべき。

#### `terraform plan`が成功しても`apply`が失敗する

`terraform plab`はステートファイルに記入されているリソースのみ考慮するため、管理外のリソースがある場合は失敗する可能性がある。  
Terraform を使い始めたら Terraform のみを使ってリソースの操作をすること。  
既存のインフラがある場合は、import コマンドを使用すること。

#### リファクタリングは難しい

名前の変更はリソースの削除を伴うので、ダウンタイムが発生する。

いつも plan コマンドを使うこと  
削除を行う前に作成を行うこと  
リファクタリングをする場合はステートの変更が必要になる。  
イミュータブルなパラメータがある。

## シークレット管理

**絶対にシークレットをプレーンテキストで保存するな!!**

### シークレット管理ツール

#### 保存するシークレットの種類

- 個人シークレット: 個人に紐づくもの。ユーザ ID とパスワード、SSH キーなど
- 顧客シークレット: 顧客に紐づくもの。顧客のパスワードや、個人情報
- インフラシークレット: インフラに紐づくもの。データベースのパスワード、API キー、TLS 証明書

#### シークレットの保存方法

##### ファイルベースのシークレットストア

暗号化キーが必要。キーマネジメントサービスなど保存する

##### 集中型のシークレットストア

ネットワーク越しにアクセスする Web サービスであることが多い

### シークレット管理ツールと Terraform

Terraform が扱う 3 つの領域

- プロバイダ
- リソースとデータソース
- ステートファイルとプランファイル

#### プロバイダへの認証

人が持つ場合はパスワード管理ソフトがおすすめ  
CI/CD が持つ場合はネイティブの機能を使用する

#### リソースとデータソース

保存方法は 3 つ

- 環境変数:
- 暗号化されたファイル: 外部に暗号化キーをおいておく
- 外部のシークレットストア

#### ステートファイルとプランファイル

Terraform リソースやデータに渡したシークレットは全て Terraform ステートファイルにプレーンテキストで保存される。

暗号化をサポートするバックエンドに保存すること  
Terraform バックエンドにアクセスできる人を厳しく制御すること

## 複数プロバイダの使用

Terraform は Terrafrom コアと Terraform プロバイダの２つに分けることができる。

- コア: Terraform のバイナリ、基本機能
- プロバイダ: コアに対するプラグイン。各プラットフォーム(AWS など)に対するもの

required_provider は常に書くこと

複数のプロバイダを使う場合はエイリアスを使用する

ここはあまり使わなそうなので、飛ばす

## 本番レベルの Terraform コード

本番レベルのインフラ: 会社の命運がかかっているタイプのインフラ

本番レベルのプロジェクトを 0 から構築するには時間がかかる。以下の表が目安

| インフラの種類                               | 例                                                       | 必要な期間 |
| -------------------------------------------- | -------------------------------------------------------- | ---------- |
| マネージドサービス                           | Amazon RDS                                               | 1-2 week   |
| セルフマネージドな分散システム(ステートレス) | AGS 上の Node.js アプリクラスタ                          | 2-4 week   |
| セルフマネージドな分散システム(ステートフル) | Elasticsearch クラスタ                                   | 2-4 month  |
| アーキテクチャ全体                           | アプリケーション、データストア、ロードバランサ、監視など | 6-36 month |

### 本番レベルのインフラを構築するには時間がかかる理由

1. DevOpsが未成熟であるから
2. 依存関係が深くなりがちで、目的を達成するのに時間がかかるから
3. 本番用のインフラを準備するのに必要なタスクリストがそもそも長いから

### 本番レベルのインフラのチェックリスト

あまりに色々とあるので、タスクの名前だけを列挙する

- インストール
- 設定
- プロビジョニング
- デプロイ
- 高可用性
- スケーラビリティ
- パフォーマンス
- ネットワーク
- セキュリティ
- メトリクス
- ログ
- データバックアップ
- コスト最適化
- ドキュメント化
- テスト

インフラの新しい仕組みに取り掛かるたびにチェックリストを全て確認すること  
実装した項目と実装しなかった理由を記録すること

### 本番レベルのインフラモジュール

上のチェックリストに該当する、再利用可能なモジュールを作成するベストプラクティス

- 小さなモジュール
- 組み合わせ可能なモジュール
- テスト可能なモジュール
- バージョン管理されたモジュール
- Terraformモジュールの先に

#### 小さなモジュール

- 大きなモジュールは遅い: デプロイが
- 大きなモジュールはセキュアでない: 権限の問題
- 大きなモジュールはハイリスク: コードの影響範囲
- 理解/レビューしにくい
- テストしにくい

#### 組み合わせ可能なモジュール

- 関数の合成: 関数の入力と出力を繋げること
- 副作用が少ないこと: 入力はモジュールの入力パラメータとして受け取り、それ以外からは受け取らない。出力も

#### テスト可能なモジュール

examples/以下にモジュールのテスト用のコードを用意する  
providerをセットしたり、backendを設置したりするコードを追加する  
自己正常性確認が可能なモジュールにするためにterraformではバリデーションと事前/事後条件を設定する

##### バリデーション

複数のバリデーションブロックをつけることも可能。ただし、別のパラメータを参照することはできない。

```hcl
variable "instance_type" {
    description = "The type of EC2 instance to run (e.g. t2.micro)"
    type = string

    validation {
        condition = contains(["t2.micro", "t3.micro"], var.instance_type)
        error_message = "Only free tier is allowed: t2.micro | t3.micro."
    }
}
```

##### 事前条件と事後条件

precondition(事前条件)とpostcondition(事後条件)ブロック  

###### preconditionブロック: applyを実行する前にエラーを補足  

```hcl
resource "aws_launch_template" "example" {
    image_id = var.ami
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.instance.id]
    user_data = var.user_data

    # Auto scaling グループと起動テンプレートを組み合わせるときは必須
    lifecycle {
        create_before_destroy = true
        precondition {
            condition = data.aws_ec2_instance_type.instance.free_tier_eligible
            error_message = "${var.instance_type} is not part of the AWS Free Tier!"
        }
    }
}
```

###### postconditionブロックはapplyを実行した後のエラーを補足する  

```hcl
resource "aws_autoscaling_group" "example" {
  name = var.cluster_name
  launch_template {
    id      = aws_launch_template.example.id
    version = aws_launch_template.example.latest_version
  }
  
  # ASGが2つ以上のavailablity zoneにデプロイされたことを確認する
  lifecycle {
    postcondition {
        condition = length(self.availability_zones) > 1
        error_message = "You must use more than one AZ for high availability!"
    }
  }
}
```

self文: 囲まれているリソースの出力を参照する用途で、postcondition, connection, provisionerの各ブロック内でのみ使用可能

`self.<ATTRIBUTE>`

##### バリデーション、事前条件、事後条件の使いどき

本番のコードでは全てを含めること

- 基本的な入力のサニタイズにはvalidationブロックを使用
- 基本的な前提のチェックにはpreconditionブロックを使用
- 基本的な約束事を強制するにはpostconditionブロックを使用
- さらに高度な前提条件や約束事の強制には自動テストツールを使用する

##### バージョン管理されたモジュール

モジュールに対するバージョン管理は2種類

- モジュールの依存関係のバージョン管理
- モジュール自体のバージョン管理

###### モジュールの依存圏系のバージョン管理

以下は全てバージョン固定する

- Terraform コア: 依存するTerraform バイナリ
- プロバイダ: 依存するawsなどのプロバイダ
- モジュール: moduleブロックでダウンロードする依存するモジュールのバージョン