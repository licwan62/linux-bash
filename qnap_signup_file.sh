#!/bin/sh
# 注册 jellyfin 文件夹为 QNAP 共享文件夹
# 适用于 QTS / QuTS hero 环境

SHARE_NAME="jellyfin"
COMMENT="Jellyfin Data"

SHARE_PATH="/share/CACHEDEV1_DATA/${SHARE_NAME}"
OWNER="admin"
GROUP="administrators"

echo "👉 检查路径是否存在..."
if [ ! -d "$SHARE_PATH" ]; then
  echo "❌ 目录不存在：$SHARE_PATH"
  exit 1
fi

echo "👉 修改权限为 ${OWNER}:${GROUP}"
chown -R ${OWNER}:${GROUP} "$SHARE_PATH"
chmod -R 775 "$SHARE_PATH"

echo "👉 向 QNAP 注册共享文件夹..."
/sbin/setcfg SHARE_DEF "${SHARE_NAME}" "Path" "$SHARE_PATH" -f /etc/config/smb.conf
/sbin/setcfg SHARE_DEF "${SHARE_NAME}" "Comment" "$COMMENT" -f /etc/config/smb.conf
/sbin/setcfg SHARE_DEF "${SHARE_NAME}" "Public" "yes" -f /etc/config/smb.conf
/sbin/setcfg SHARE_DEF "${SHARE_NAME}" "Oplocks" "yes" -f /etc/config/smb.conf
/sbin/setcfg SHARE_DEF "${SHARE_NAME}" "WORM" "no" -f /etc/config/smb.conf
/sbin/setcfg SHARE_DEF "${SHARE_NAME}" "AccessRight" "RW" -f /etc/config/smb.conf

echo "👉 重新加载共享配置..."
/etc/init.d/smb.sh restart
/etc/init.d/Qthttpd.sh restart

echo "✅ 已注册共享文件夹：${SHARE_NAME}"
echo "现在可以在 File Station 中看到它。"