#!/bin/bash
set -e

echo "=== QNAP Container Station Docker 镜像加速配置脚本 ==="

# 自动检测 Container Station 目录
CS_PATH="/share/CACHEDEV1_DATA/.qpkg/container-station"
if [ ! -d "$CS_PATH" ]; then
  echo "❌ 未找到 Container Station 路径，脚本退出。"
  exit 1
fi

DOCKER_JSON="/etc/docker.json"

# 检查 jq 工具是否存在
if ! command -v jq >/dev/null 2>&1; then
  echo "⚠️  未找到 jq，正在临时安装..."
  $CS_PATH/bin/busybox wget -qO /tmp/jq https://ghproxy.com/https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 || true
  chmod +x /tmp/jq && alias jq=/tmp/jq
fi

# 备份原配置
cp "$DOCKER_JSON" "$DOCKER_JSON.bak.$(date +%Y%m%d%H%M%S)"
echo "📦 已备份原配置到 $DOCKER_JSON.bak"

# 添加 registry-mirrors
MIRRORS='[
  "https://docker.m.daocloud.io",
  "https://mirror.ccs.tencentyun.com",
  "https://hub.uuuadc.top"
]'

if grep -q "registry-mirrors" "$DOCKER_JSON"; then
  echo "🔁 检测到已有 registry-mirrors，更新中..."
  jq ".\"registry-mirrors\" = $MIRRORS" "$DOCKER_JSON" > /tmp/docker.json.tmp
else
  echo "➕ 添加 registry-mirrors 配置..."
  jq ". + {\"registry-mirrors\": $MIRRORS}" "$DOCKER_JSON" > /tmp/docker.json.tmp
fi

mv /tmp/docker.json.tmp "$DOCKER_JSON"
echo "✅ 已更新 $DOCKER_JSON"

# 重启 Container Station 服务
echo "🔄 正在重启 Container Station..."
$CS_PATH/container-station.sh restart

# 验证结果
echo "🧪 验证镜像源配置..."
$CS_PATH/bin/docker info | grep -A3 Mirrors || echo "⚠️ 未检测到镜像源，可能需要手动重启 NAS。"

echo "🎉 完成！Docker 镜像加速器已配置成功。"