# Talon Pilot · tp-agent 一键安装(Windows / PowerShell)。
#   irm https://agents.deeplan.ai/install.ps1 | iex
#
# 从 GitHub Release 下 tp-agent 装进用户目录并加入 PATH。release 版默认连线上,
# 装完直接 `tp-agent login` 免填 URL。
$ErrorActionPreference = "Stop"

$repo  = "darkmice/talon-pilot-client"
$asset = "tp-agent-windows-x64.zip"
$url   = "https://github.com/$repo/releases/latest/download/$asset"

$tmp = Join-Path $env:TEMP ("tp-agent-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
  Write-Host "↓ 下载 tp-agent ($asset)…"
  Invoke-WebRequest -Uri $url -OutFile "$tmp\$asset"
  Expand-Archive -Path "$tmp\$asset" -DestinationPath $tmp -Force

  $dest = Join-Path $env:LOCALAPPDATA "Programs\tp-agent"
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Move-Item -Force "$tmp\tp-agent.exe" "$dest\tp-agent.exe"

  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*$dest*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$dest", "User")
    Write-Host "✓ 已把 $dest 加入用户 PATH(新开终端生效)"
  }
  Write-Host "✓ 已安装: $dest\tp-agent.exe"
  Write-Host ""
  Write-Host "下一步登录(已默认连线上,无需填 URL):"
  Write-Host "    tp-agent login"
} finally {
  Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
