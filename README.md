# talon-pilot-client (tp-agent)

**tp-agent** 是 Talon Pilot 的本地 edge 客户端:在你的机器上运行,登录后把本机注册为
edge node,通过安全长连接(WebSocket + TLS)与 Talon Pilot 通信,托管本地工作区、跑预览
dev server 与终端 PTY。无需公网暴露本机。

> 本仓只放 **构建/发布产物**。tp-agent 源码在私有主仓 `talon-pilot`,二进制由本仓的
> GitHub Actions 从主仓拉源码跨平台编译后发到 [Releases](../../releases)。

## 安装

到 [Releases](../../releases) 下对应平台的包,解压后把 `tp-agent` 放进 PATH:

| 平台 | 包 |
|------|-----|
| macOS (Apple Silicon) | `tp-agent-macos-arm64.tar.gz` |
| macOS (Intel) | `tp-agent-macos-x64.tar.gz` |
| Linux (x64, glibc ≥ 2.35) | `tp-agent-linux-x64.tar.gz` |
| Windows (x64) | `tp-agent-windows-x64.zip` |

```bash
# macOS / Linux 示例
tar xzf tp-agent-macos-arm64.tar.gz
sudo mv tp-agent /usr/local/bin/
tp-agent --help
```

## 注册到线上环境

```bash
tp-agent login \
  --api-base-url https://agents.deeplan.ai \
  --web-base-url https://agents.deeplan.ai
```

浏览器会打开 Talon Pilot 完成授权(需先用邮箱登录过),tp-agent 拿到 CLI key 后自动注册
为 edge node 并转后台 daemon。之后本机会出现在 Web 端「已注册的本地 Agent」列表中。

- 无浏览器 / CI:`tp-agent login --key <ApiKey> --api-base-url https://agents.deeplan.ai`
- 常用:`tp-agent status` / `tp-agent stop` / `tp-agent accounts list`

> 默认连本地 `http://127.0.0.1:3100`(开发用)。连线上务必带 `--api-base-url` /
> `--web-base-url`。

## 构建(维护者)

GitHub Actions(`.github/workflows/release.yml`)负责构建。需要在本仓 **Settings →
Secrets and variables → Actions** 配两个 secret:

- `MAIN_REPO_HOST` — 私有主仓的 clone 主机+路径(形如 `<host>/<owner>/talon-pilot.git`)。
- `XGIT_TOKEN` — 对该主仓有**读权限**的 access token。Actions 用它 clone 主仓源码。

两个公开依赖仓,Actions 自动 clone、免 token:
- `talon-bin`(含 `talon-sys` + libtalon):libtalon 由 build.rs 从其公开 release 自动下载。
- `talon-sandbox-sdk-rust`(`talon-org`):main 的云端预览依赖它(path 依赖)。

手动构建:Actions → **build-tp-agent** → Run workflow(可填分支)。
发版:推一个 `v*` tag,会自动构建并发 Release。
