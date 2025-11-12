#!/bin/bash
# =========================================================
# 💻  MySQL 8.0 客户端安装脚本（CentOS 7）
# 作者: Licheng
# 说明: 仅安装 mysql-community-client，适用于远程运维机或测试主机
# =========================================================

set -e

echo "💻 开始安装 MySQL 客户端..."

# ---------- 一、同步系统时间 ----------
echo "⏰ 同步系统时间..."
yum install -y ntpdate >/dev/null 2>&1 || true
ntpdate ntp.aliyun.com || true
hwclock -w || true
date -R

# ---------- 二、卸载系统自带的 MariaDB / MySQL ----------
echo "🧹 清除旧的 MariaDB / MySQL 组件..."
for pkg in $(rpm -qa | grep -Ei 'mysql|mariadb' || true); do
    echo "  → 移除: $pkg"
    rpm -e --nodeps "$pkg" || true
done
echo "✅ 清理完成。"

# ---------- 三、安装 MySQL 官方 YUM 源 ----------
echo "📦 安装 MySQL 官方 YUM 源..."
yum -y localinstall https://dev.mysql.com/get/mysql80-community-release-el7-9.noarch.rpm
sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/mysql-community.repo

# ---------- 四、安装 MySQL 客户端 ----------
echo "💾 安装 mysql-community-client..."
yum install -y mysql-community-client

# ---------- 五、验证安装 ----------
echo "🧩 验证 MySQL 客户端安装结果..."
mysql --version || {
    echo "❌ MySQL 客户端安装失败，请检查网络或软件源。"
    exit 1
}

echo "🎉 MySQL 客户端安装完成！"
echo "✅ 使用示例： mysql -h <服务器IP> -u root -p"
