#!/bin/bash
# =========================================================
# 🧱  MySQL 8.0 服务端 + 客户端安装脚本（CentOS 7）
# 作者: Licheng
# 说明: 安装 mysql-community-server + mysql-community-client
#       自动同步时间、卸载旧版、初始化 root 密码（交互输入）
# =========================================================

set -e

echo "🧱 开始安装 MySQL Server + Client"

# ---------- 一、同步系统时间 ----------
echo "⏰ 同步系统时间..."
yum install -y ntpdate >/dev/null 2>&1 || true
ntpdate ntp.aliyun.com || true
hwclock -w || true
date -R

# ---------- 二、卸载旧版本 ----------
echo "🧹 清除旧的 MariaDB / MySQL 包..."
for pkg in $(rpm -qa | grep -Ei 'mysql|mariadb' || true); do
  echo "  → 移除: $pkg"
  rpm -e --nodeps "$pkg" || true
done
echo "✅ 清理完成。"

# ---------- 三、安装 MySQL 官方源 ----------
echo "📦 安装 MySQL 官方 YUM 源..."
yum -y localinstall https://dev.mysql.com/get/mysql80-community-release-el7-9.noarch.rpm
sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/mysql-community.repo

# ---------- 四、安装 MySQL Server + Client ----------
echo "💾 安装 MySQL Server 和 Client..."
yum install -y mysql-community-server mysql-community-client

# ---------- 五、启动并设置开机自启 ----------
systemctl enable mysqld
systemctl start mysqld

# ---------- 六、获取临时密码 ----------
TEMP_PWD=$(grep 'temporary password' /var/log/mysqld.log | tail -1 | awk '{print $NF}' || true)
echo "📋 提取到临时密码: ${TEMP_PWD:-未找到，请检查 /var/log/mysqld.log}"

# ---------- 七、交互式设置新密码 ----------
if [ -r /dev/tty ]; then
  echo -n "🔑 请输入新的 root 密码（≥8 位，含大小写字母+数字+符号）: " >/dev/tty
  read -s NEW_PWD </dev/tty
  echo >/dev/tty
  echo -n "🔁 请再次输入确认密码: " >/dev/tty
  read -s CONFIRM_PWD </dev/tty
  echo >/dev/tty
else
  echo "❌ 无法交互，请使用交互式终端运行。"
  exit 1
fi

if [ "$NEW_PWD" != "$CONFIRM_PWD" ]; then
  echo "❌ 两次输入密码不一致，安装中止。"
  exit 1
fi

# ---------- 八、运行安全配置向导 ----------
echo "🛡️ 执行 mysql_secure_installation..."
yum install -y expect >/dev/null 2>&1 || true

export TEMP_PWD
export NEW_PWD

expect <<'EOF'
set timeout 300
spawn mysql_secure_installation
expect {
  -re "Enter password for user root:" { send -- "$env(TEMP_PWD)\r"; exp_continue }
  -re "New password:" { send -- "$env(NEW_PWD)\r"; exp_continue }
  -re "Re-enter new password:" { send -- "$env(NEW_PWD)\r"; exp_continue }
  -re "Change the password for root ?" { send -- "n\r"; exp_continue }
  -re "Remove anonymous users?" { send -- "y\r"; exp_continue }
  -re "Disallow root login remotely?" { send -- "n\r"; exp_continue }
  -re "Remove test database and access to it?" { send -- "y\r"; exp_continue }
  -re "Reload privilege tables now?" { send -- "y\r"; exp_continue }
  eof
}
EOF

# ---------- 九、验证登录 ----------
echo "🔐 验证新密码是否可用..."
sleep 2
if mysql -uroot -p"${NEW_PWD}" -e "SELECT VERSION();" >/dev/null 2>&1; then
  echo "✅ 登录验证通过。"
else
  echo "❌ 登录验证失败，请检查密码或日志。"
  exit 1
fi

# ---------- 十、创建远程 root 账户 ----------
echo "👤 创建 root@'%' 并授权..."
mysql -uroot -p"${NEW_PWD}" <<SQL
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${NEW_PWD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

# ---------- 十一、验证版本 ----------
echo "🧩 最终验证..."
mysql -uroot -p"${NEW_PWD}" -e "SELECT VERSION(); SHOW DATABASES;"

echo "🎉 MySQL 8.0 安装完成！"
echo "✅ 登录命令：mysql -u root -p"
