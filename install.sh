#!/bin/sh
# Talon Pilot · tp-agent 一键安装(macOS / Linux)。
#   curl -fsSL https://agents.deeplan.ai/install.sh | sh
#
# 从 GitHub Release 下对应平台的 tp-agent 装进 PATH,随后自动准备默认的
# Open Interpreter runtime,最后在可交互终端里自动登录。
set -e

REPO="${TP_AGENT_REPO:-darkmice/talon-pilot-client}"
OS="$(uname -s)"
ARCH="$(uname -m)"

# ── 着色 ── 仅在 stdout 是 tty 时启用 ANSI(管道/重定向里不上色,免乱码)。
if [ -t 1 ]; then
  C_BOLD="$(printf '\033[1m')"; C_DIM="$(printf '\033[2m')"
  C_GREEN="$(printf '\033[32m')"; C_BLUE="$(printf '\033[34m')"
  C_YELLOW="$(printf '\033[33m')"; C_CYAN="$(printf '\033[36m')"; C_RESET="$(printf '\033[0m')"
else
  C_BOLD=; C_DIM=; C_GREEN=; C_BLUE=; C_YELLOW=; C_CYAN=; C_RESET=
fi

case "${OS}-${ARCH}" in
  Darwin-arm64)             ASSET="tp-agent-macos-arm64.tar.gz" ;;
  Darwin-x86_64)            ASSET="tp-agent-macos-x64.tar.gz" ;;
  Linux-x86_64|Linux-amd64) ASSET="tp-agent-linux-x64.tar.gz" ;;
  *) echo "${C_YELLOW}不支持的平台: ${OS}-${ARCH}${C_RESET}(目前支持 macOS arm64/x64、Linux x64)" >&2; exit 1 ;;
esac

URL="${TP_AGENT_ASSET_URL:-https://github.com/${REPO}/releases/latest/download/${ASSET}}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf '%s↓%s 下载 tp-agent %s(%s)%s…\n' "$C_BLUE" "$C_RESET" "$C_DIM" "$ASSET" "$C_RESET"
curl -fsSL "$URL" -o "$TMP/$ASSET"
tar -xzf "$TMP/$ASSET" -C "$TMP"

DEST="${TP_AGENT_INSTALL_DIR:-/usr/local/bin}"
if [ -z "${TP_AGENT_INSTALL_DIR:-}" ] && [ ! -w "$DEST" ]; then
  DEST="$HOME/.local/bin"
fi
mkdir -p "$DEST"
install -m 0755 "$TMP/tp-agent" "$DEST/tp-agent" 2>/dev/null \
  || { cp "$TMP/tp-agent" "$DEST/tp-agent"; chmod +x "$DEST/tp-agent"; }

BIN="$DEST/tp-agent"
printf '%s✓%s 已安装: %s%s%s\n' "$C_GREEN" "$C_RESET" "$C_BOLD" "$BIN" "$C_RESET"

case ":$PATH:" in
  *":$DEST:"*) PATH_OK=1 ;;
  *) PATH_OK=0
     printf '%s⚠%s %s 不在 PATH,请加入:  %sexport PATH="%s:$PATH"%s\n' \
       "$C_YELLOW" "$C_RESET" "$DEST" "$C_CYAN" "$DEST" "$C_RESET" ;;
esac

# Open Interpreter 是 Talon 的默认 runtime。由刚安装好的 tp-agent 做幂等
# bootstrap:已有兼容的 `interpreter acp` 就复用,否则下载 Talon 已验证的官方
# checksum-backed release。失败时安装器返回非零,不把“只有壳、不能执行”误报成完成。
printf '\n%s→%s 准备默认 runtime: Open Interpreter…\n' "$C_BLUE" "$C_RESET"
if ! "$BIN" runtime ensure; then
  printf '%s✗%s Open Interpreter 安装或验证失败。修复网络后可重跑安装器，或执行: %s%s runtime ensure%s\n' \
    "$C_YELLOW" "$C_RESET" "$C_CYAN" "$BIN" "$C_RESET" >&2
  exit 1
fi

# 装完直接进登录,省掉用户再敲一条命令。
# 仅在**可交互终端**才自动跑(login 会弹浏览器走 OAuth,要 tty)。
# `curl ... | sh` 这种管道安装 stdin 不是 tty(-t 0 为假)→ 不自动 login,
# 只打印提示,避免在无 tty 环境里卡住或反复弹失败。
if [ -t 0 ] && [ -t 1 ]; then
  printf '\n%s→%s 开始登录…\n' "$C_BLUE" "$C_RESET"
  # 用绝对路径调,绕开 PATH 还没生效的情况(刚装、当前 shell PATH 未更新)。
  "$BIN" login || {
    printf '\n%s⚠%s 自动登录未完成,稍后手动重试:  %stp-agent login%s\n' \
      "$C_YELLOW" "$C_RESET" "$C_CYAN" "$C_RESET"
  }
else
  # 非交互(管道安装 / CI):给出明确下一步。
  if [ "$PATH_OK" = "1" ]; then
    printf '\n下一步:  %stp-agent login%s\n' "$C_CYAN" "$C_RESET"
  else
    printf '\n下一步:  %s%s login%s\n' "$C_CYAN" "$BIN" "$C_RESET"
  fi
fi
