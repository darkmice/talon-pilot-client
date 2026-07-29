# talon-pilot-client (tp-agent)

**tp-agent** 是 Talon Pilot 的本地 edge 客户端:在你的机器上运行,登录后把本机注册为
edge node,通过安全长连接(WebSocket + TLS)与 Talon Pilot 通信,托管本地工作区、跑预览
dev server 与终端 PTY。无需公网暴露本机。

> 本仓只放 **构建/发布产物**。tp-agent 源码在私有主仓 `talon-pilot`,二进制由本仓的
> GitHub Actions 从主仓拉源码跨平台编译后发到 [Releases](../../releases)。

## 安装

**一键安装(推荐)**

macOS / Linux:
```sh
curl -fsSL https://agents.deeplan.ai/install.sh | sh
```

Windows(PowerShell):
```powershell
irm https://agents.deeplan.ai/install.ps1 | iex
```

安装器会同时安装 `tp-agent` 与配套控制面命令 `tp`，再由
`tp-agent runtime ensure` 自动安装或复用支持 ACP 的 Open Interpreter，
最后进入登录流程。若是受控环境需要显式跳过默认 runtime，可在安装前设置
`TP_SKIP_OPEN_INTERPRETER_INSTALL=1`。

**手动下载**:到 [Releases](../../releases) 下对应平台的包，解压后把
`tp-agent` 和 `tp` 一起放进同一个 PATH 目录。
(macOS arm64/x64 · Linux x64,glibc ≥ 2.35 · Windows x64)

## 注册到线上环境

release 版**已默认连 agents.deeplan.ai**,装完直接:

```bash
tp-agent login
```

浏览器会打开完成授权(需先用邮箱登录过 Talon Pilot),tp-agent 拿到 CLI key 后自动注册
为 edge node 并转后台 daemon,本机随即出现在 Web 端「已注册的本地 Agent」列表中。

- 无浏览器 / CI:`tp-agent login --key <ApiKey>`
- 连别的环境(如本地 dev):`tp-agent login --api-base-url http://127.0.0.1:3100 --web-base-url http://127.0.0.1:5174`
- 常用:`tp-agent status` / `tp-agent stop` / `tp-agent accounts list`

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
