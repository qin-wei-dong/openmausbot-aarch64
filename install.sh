#!/bin/sh
# OpenMausBot aarch64 离线部署脚本
# 在 UOS 20 (aarch64) 内网机上运行；全程不访问外网。
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "================================================"
echo " OpenMausBot aarch64 离线部署"
echo " 离线包根目录: $BASE_DIR"
echo "================================================"

# ---------- 1. 安装 Node 24 (linux-arm64) ----------
if node -v 2>/dev/null | grep -q '^v24'; then
  echo "[1/5] Node 24 已存在: $(node -v)，跳过"
else
  echo "[1/5] 解压 Node 24 linux-arm64..."
  tar xf "$BASE_DIR/node-v24.22.3-linux-arm64.tar.xz" -C "$BASE_DIR"
  export PATH="$BASE_DIR/node-v24.22.3-linux-arm64/bin:$PATH"
  echo "      Node: $(node -v) / $(uname -m)"
fi

# ---------- 2. 启用 pnpm 10.33.0 ----------
echo "[2/5] 启用 pnpm 10.33.0 (corepack，离线)..."
corepack enable
# 若 corepack 缓存中没有 pnpm，用离线包内的 tgz 安装
if ! pnpm -v 2>/dev/null | grep -q '10.33.0'; then
  npm install -g --offline "$BASE_DIR/pnpm-10.33.0.tgz" 2>/dev/null \
    || npm install -g "$BASE_DIR/pnpm-10.33.0.tgz"
fi
echo "      pnpm: $(pnpm -v)"

# ---------- 3. 配置 pnpm store 指向离线目录 ----------
echo "[3/5] 配置 pnpm store 指向离线 store..."
pnpm config set store-dir "$BASE_DIR/pnpm-store"

# ---------- 4. 离线重建依赖 ----------
echo "[4/5] 离线重建 node_modules (pnpm install --offline)..."
cd "$BASE_DIR/source"
pnpm install --offline --frozen-lockfile

# ---------- 5. 写模型接入配置（若不存在）----------
echo "[5/5] 检查模型接入配置..."
CONFIG_DIR="$HOME/.openmausbot"
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config.json" ]; then
  cp "$BASE_DIR/config.json.template" "$CONFIG_DIR/config.json"
  echo "      已生成配置模板 -> $CONFIG_DIR/config.json"
  echo "      !! 请先编辑该文件，填入内网模型地址与 key !!"
else
  echo "      配置已存在，保留: $CONFIG_DIR/config.json"
fi

echo ""
echo "================================================"
echo " 部署完成。启动命令："
echo "   cd $BASE_DIR/source"
echo "   export PATH=\"$BASE_DIR/node-v24.22.3-linux-arm64/bin:\$PATH\""
echo "   pnpm omb serve --lan"
echo " 然后用浏览器打开终端打印的 pairing link。"
echo " 注意： dist/ 前端已构建好，浏览器可正常显示页面。"
echo "================================================"
