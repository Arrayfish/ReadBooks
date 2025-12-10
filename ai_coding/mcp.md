# [MCP (Model Context Protocol)](https://modelcontextprotocol.io/docs/getting-started/intro)

コーディング用のMCPに読ませると、APIを使って外部サービスと連携することができる。

## 主なMCP

### GitHub 

PATが必要

### Backlog
APIキーが必要

### Context7

ライブラリの最新のドキュメントが参照できる
APIキーはオプションなので大丈夫

## 各種IDEのworkspaceのmcp設定

### VSCode

.vscode/mcp.jsonにファイルを作成

```json
{
	"servers": {
		"io.github.github/github-mcp-server": {
			"type": "http",
			"url": "https://api.githubcopilot.com/mcp/",
			"headers": {
				"Authorization": "${input:Authorization}"
			},
			"gallery": "https://api.mcp.github.com",
			"version": "0.24.0"
		},
		"io.github.upstash/context7": {
			"type": "stdio",
			"command": "npx",
			"args": [
				"@upstash/context7-mcp@1.0.31"
			],
			"env": {
				"CONTEXT7_API_KEY": "${input:CONTEXT7_API_KEY}"
			},
			"gallery": "https://api.mcp.github.com",
			"version": "1.0.31"
		},
    "backlog": {
      "command": "docker",
      "args": [
        "run",
        "--pull", "always",
        "-i",
        "--rm",
        "-e", "BACKLOG_DOMAIN",
        "-e", "BACKLOG_API_KEY",
        "ghcr.io/nulab/backlog-mcp-server"
      ],
      "env": {
        "BACKLOG_DOMAIN": "your-domain.backlog.com",
        "BACKLOG_API_KEY": "${input:BACKLOG_API_KEY}"
      }
    }
	},
	"inputs": [
		{
			"id": "Authorization",
			"type": "promptString",
			"description": "Authentication token (PAT or App token)",
			"password": true
		},
		{
			"id": "CONTEXT7_API_KEY",
			"type": "promptString",
			"description": "API key for authentication",
			"password": true
		},
    {
			"id": "BACKLOG_API_KEY",
			"type": "promptString",
			"description": "API key for authentication",
			"password": true
		}
	]
}
```

### Cursor

設定からMCPサーバを追加

```json
{
  "mcpServers": {
    "backlog": {
      "command": "docker",
      "args": [
        "run",
        "--pull",
        "always",
        "-i",
        "--rm",
        "-e",
        "BACKLOG_DOMAIN",
        "-e",
        "BACKLOG_API_KEY",
        "-e",
        "ENABLE_TOOLSETS",
        "ghcr.io/nulab/backlog-mcp-server"
      ],
      "env": {
        "BACKLOG_DOMAIN": "digitalkey.backlog.com",
        "BACKLOG_API_KEY": "your_backlog_api_key",
        "ENABLE_TOOLSETS": "space,project,issue"
      }
    },
    "context7": {
      "url": "https://mcp.context7.com/mcp",
      "headers": {}
    },
    "GitHub": {
      "command": "docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server",
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "your_github_personal_access_token"
      },
      "args": []
    }
  }
}
```