#!/bin/sh
# Talon Pilot · tp-agent 一键安装(macOS / Linux)。
#   curl -fsSL https://agents.deeplan.ai/install.sh | sh
#
# 从 GitHub Release 下对应平台的 tp-agent 装进 PATH。release 版默认连线上,
# 装完直接 `tp-agent login` 免填 URL。
set -e

REPO="darkmice/talon-pilot-client"
OS="$(uname -s)"
ARCH="$(uname -m)"

case "${OS}-${ARCH}" in
  Darwin-arm64)             ASSET="tp-agent-macos-arm64.tar.gz" ;;
  Darwin-x86_64)            ASSET="tp-agent-macos-x64.tar.gz" ;;
  Linux-x86_64|Linux-amd64) ASSET="tp-agent-linux-x64.tar.gz" ;;
  *) echo "不支持的平台: ${OS}-${ARCH}(目前支持 macOS arm64/x64、Linux x64)" >&2; exit 1 ;;
esac

URL="https://github.com/${REPO}/releases/latest/download/${ASSET}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "↓ 下载 tp-agent (${ASSET})…"
curl -fsSL "$URL" -o "$TMP/$ASSET"
tar -xzf "$TMP/$ASSET" -C "$TMP"

DEST="/usr/local/bin"
[ -w "$DEST" ] || DEST="$HOME/.local/bin"
mkdir -p "$DEST"
install -m 0755 "$TMP/tp-agent" "$DEST/tp-agent" 2>/dev/null \
  || { cp "$TMP/tp-agent" "$DEST/tp-agent"; chmod +x "$DEST/tp-agent"; }

echo "✓ 已安装: $DEST/tp-agent"
case ":$PATH:" in
  *":$DEST:"*) ;;
  *) echo "⚠ $DEST 不在 PATH,请加入,例如: export PATH=\"$DEST:\$PATH\"" ;;
esac

echo ""
echo "下一步登录(已默认连线上,无需填 URL):"
echo "    tp-agent login"
