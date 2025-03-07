# CIツールまとめ

## セキュリティ

### Checkov
セキュリティベストプラクティス
コンプライアンス
設定ミスのチェック
https://www.checkov.io/

### Trivy(tfsec)
セキュリティ問題、設定ミス、未使用のリソースの特定

```bash
terraform plan --out tfplan
trivy config tfplan
```

ダウンロードしたモジュールは除外する
`trivy config --tf-exclude-downloaded-modules ./configs`

脅威度にをフィルタリング
``trivy config --severity CRITICAL, MEDIUM terraform-infra`

シークレットのチェックと脆弱性のチェックはfs(FileSystemコマンドで行う)  
--scannersオプションで上のconfigコマンドと同じことが可能
`trivy fs --scanners misconfig ./`

`trivy config <ディレクトリやファイル>`
https://aquasecurity.github.io/trivy/v0.56/tutorials/misconfiguration/terraform/
https://aquasecurity.github.io/trivy/v0.56/docs/coverage/iac/terraform/#terraform

### terrascan
脆弱性スキャンとコンプライアンスチェック
https://github.com/tenable/terrascan

## リンタ

- tflint
- terraform validate
