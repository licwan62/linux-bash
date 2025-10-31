#!/bin/bash
set -e

echo "=== Jellyfin 一键部署脚本 (for QNAP TS464C) ==="

# 检测 Container Station 路径
CS_PATH="/share/CACHEDEV1_DATA/.qpkg/container-station"
DOCKER="$CS_PATH/bin/docker"

if [ ! -x "$DOCKER" ]; then
  echo "❌ 未找到 Docker 可执行文件: $DOCKER"
  echo "请先安装并启动 Container Station。"
  exit 1
fi

# 创建持久化目录
JELLYFIN_PATH="/share/CACHEDEV1_DATA/jellyfin"
mkdir -p "$JELLYFIN_PATH/config" "$JELLYFIN_PATH/cache" "$JELLYFIN_PATH/media"
echo "📁 创建目录: $JELLYFIN_PATH/{config,cache,media}"

# 拉取镜像（自动尝试国内源）
echo "🚀 拉取 Jellyfin 镜像..."
$DOCKER pull jellyfin/jellyfin:latest || $DOCKER pull ghcr.io/jellyfin/jellyfin:latest

# 若容器已存在则先删除
if $DOCKER ps -a --format '{{.Names}}' | grep -q '^jellyfin$'; then
  echo "🔁 检测到已有 jellyfin 容器，先移除..."
  $DOCKER stop jellyfin >/dev/null 2>&1 || true
  $DOCKER rm jellyfin >/dev/null 2>&1 || true
fi

# 运行容器
echo "🏃 正在启动 Jellyfin 容器..."
$DOCKER run -d \
  --name jellyfin \
  -v "$JELLYFIN_PATH/config:/config" \
  -v "$JELLYFIN_PATH/cache:/cache" \
  -v "$JELLYFIN_PATH/media:/media" \
  --net=host \
  --restart unless-stopped \
  jellyfin/jellyfin:latest

echo "✅ Jellyfin 容器已启动！"

# 检查运行状态
$DOCKER ps | grep jellyfin

IP=$(ip addr show | grep 'inet ' | grep -v 127 | awk '{print $2}' | cut -d/ -f1 | head -1)
echo "🌐 请访问: http://$IP:8096"
echo "⚙️  配置目录: $JELLYFIN_PATH/config"
echo "📦 媒体目录:  $JELLYFIN_PATH/media"
echo "🧊 缓存目录:  $JELLYFIN_PATH/cache"