# Talon Pilot · tp-agent 一键安装(Windows / PowerShell)。
#   irm https://agents.deeplan.ai/install.ps1 | iex
#
# 从 GitHub Release 下 tp-agent + 控制面辅助命令 tp 装进用户目录并加入 PATH,
# 随后自动准备默认的 Open Interpreter runtime,最后在可交互终端里自动登录。
$ErrorActionPreference = "Stop"

$repo  = if ([string]::IsNullOrWhiteSpace($env:TP_AGENT_REPO)) { "darkmice/talon-pilot-client" } else { $env:TP_AGENT_REPO }
$asset = "tp-agent-windows-x64.zip"
$url   = if ([string]::IsNullOrWhiteSpace($env:TP_AGENT_ASSET_URL)) { "https://github.com/$repo/releases/latest/download/$asset" } else { $env:TP_AGENT_ASSET_URL }

$tmp = Join-Path $env:TEMP ("tp-agent-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
  Write-Host "↓ " -ForegroundColor Blue -NoNewline
  Write-Host "下载 tp-agent " -NoNewline
  Write-Host "($asset)…" -ForegroundColor DarkGray
  Invoke-WebRequest -Uri $url -OutFile "$tmp\$asset"
  Expand-Archive -Path "$tmp\$asset" -DestinationPath $tmp -Force
  if (-not (Test-Path "$tmp\tp-agent.exe" -PathType Leaf)) {
    throw "安装包缺少 tp-agent.exe，拒绝安装"
  }
  if (-not (Test-Path "$tmp\tp.exe" -PathType Leaf)) {
    throw "安装包缺少配套控制面命令 tp.exe，拒绝安装"
  }

  $dest = if ([string]::IsNullOrWhiteSpace($env:TP_AGENT_INSTALL_DIR)) {
    Join-Path $env:LOCALAPPDATA "Programs\tp-agent"
  } else {
    $env:TP_AGENT_INSTALL_DIR
  }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Move-Item -Force "$tmp\tp.exe" "$dest\tp.exe"
  Move-Item -Force "$tmp\tp-agent.exe" "$dest\tp-agent.exe"

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*$dest*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$dest", "User")
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host "已把 $dest 加入用户 PATH" -NoNewline
    Write-Host " (新开终端生效)" -ForegroundColor DarkGray
  }
  $bin = Join-Path $dest "tp-agent.exe"
  $tpBin = Join-Path $dest "tp.exe"
  Write-Host "✓ " -ForegroundColor Green -NoNewline
  Write-Host "已安装: $bin"
  Write-Host "✓ " -ForegroundColor Green -NoNewline
  Write-Host "已安装: $tpBin"

  # Open Interpreter 是 Talon 的默认 runtime。让 tp-agent 做幂等 bootstrap:
  # 已有兼容的 `interpreter acp` 就复用,否则下载官方 checksum-backed release。
  Write-Host ""
  Write-Host "→ " -ForegroundColor Blue -NoNewline
  Write-Host "准备默认 runtime: Open Interpreter…"
  & $bin runtime ensure
  if ($LASTEXITCODE -ne 0) {
    throw "Open Interpreter 安装或验证失败。修复网络后请重跑安装器，或执行: $bin runtime ensure"
  }

  # 装完直接进登录,省掉用户再敲一条命令。仅在**可交互终端**才自动跑
  # (login 会弹浏览器走 OAuth,要交互)。`irm ... | iex` 这种管道安装不是
  # 交互式 host → 不自动 login,只打印提示,避免无 tty 环境卡住。
  if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    Write-Host ""
    Write-Host "→ " -ForegroundColor Blue -NoNewline
    Write-Host "开始登录…"
    # 用绝对路径调,绕开 PATH 还没在当前会话生效的情况(刚装)。
    try {
      & $bin login
    } catch {
      Write-Host ""
      Write-Host "⚠ 自动登录未完成,稍后手动重试:  " -ForegroundColor Yellow -NoNewline
      Write-Host "tp-agent login" -ForegroundColor Cyan
    }
  } else {
    Write-Host ""
    Write-Host "下一步:  " -NoNewline
    Write-Host "tp-agent login" -ForegroundColor Cyan
  }
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
