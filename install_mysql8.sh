#!/bin/bash
# =========================================================
# 🚀  MySQL 8.0 一键安装脚本（CentOS 7）
# 作者: Licheng
# 说明: 自动同步时间 → 清除旧依赖 → 安装 MySQL（支持 --client-only 模式）
# =========================================================

set -e

MODE="server"

# -------------------------------
# 🌐 参数解析
# -------------------------------
if [[ "$1" == "--client-only" ]]; then
  MODE="client"
  echo "💻 模式：仅安装 MySQL 客户端"
else
  echo "🧱 模式：安装 MySQL Server + 初始化配置"
fi

# -------------------------------
# 🧩 获取用户输入密码
# -------------------------------
if [[ "$MODE" == "server" ]]; then
  echo -n "🔑 请输入要设置的 MySQL root 密码（建议包含大小写字母+数字+符号）: "
  read -s NEW_PWD
  echo
  echo -n "🔁 请再次输入确认密码: "
  read -s CONFIRM_PWD
  echo
  if [[ "$NEW_PWD" != "$CONFIRM_PWD" ]]; then
    echo "❌ 两次输入的密码不一致，请重新运行脚本。"
    exit 1
  fi
fi

# -------------------------------
# 一、同步系统时间
# -------------------------------
echo "⏰ 同步系统时间..."
yum install -y ntpdate >/dev/null 2>&1
ntpdate ntp.aliyun.com
hwclock -w
date -R

# -------------------------------
# 二、卸载系统自带的 MariaDB / MySQL
# -------------------------------
echo "🧹 清除旧的 MariaDB 或 MySQL 组件..."
for pkg in $(rpm -qa | grep -Ei 'mysql|mariadb' || true); do
  echo "  → 移除: $pkg"
  rpm -e --nodeps "$pkg" || true
done
echo "✅ 清理完成。"

# -------------------------------
# 三、安装 MySQL 官方 YUM 源
# -------------------------------
echo "📦 安装 MySQL 官方 YUM 源..."
yum -y localinstall https://dev.mysql.com/get/mysql80-community-release-el7-9.noarch.rpm
sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/mysql-community.repo

# -------------------------------
# 四、安装 MySQL（根据模式）
# -------------------------------
if [[ "$MODE" == "client" ]]; then
  yum install -y mysql-community-client
  echo "✅ MySQL 客户端安装完成。"
  mysql --version
  exit 0
else
  yum install -y mysql-community-server
fi

# -------------------------------
# 五、启动 MySQL 并设置开机自启
# -------------------------------
systemctl enable mysqld
systemctl start mysqld

# -------------------------------
# 六、确认 mysqld 运行状态
# -------------------------------
echo "🔍 检查 MySQL 进程与端口..."
ps aux | grep [m]ysqld || echo "⚠️ mysqld 未运行"
ss -tnl | grep 3306 || echo "⚠️ 端口 3306 未监听"

# -------------------------------
# 七、提取临时密码
# -------------------------------
TEMP_PWD=$(grep 'temporary password' /var/log/mysqld.log | tail -1 | awk '{print $NF}')
echo "📋 临时密码: ${TEMP_PWD}"

# -------------------------------
# 八、自动化运行安全配置向导
# -------------------------------
yum install -y expect >/dev/null 2>&1

expect <<EOF
spawn mysql_secure_installation
expect "Enter password for user root:"
send "${TEMP_PWD}\r"
expect "New password:"
send "${NEW_PWD}\r"
expect "Re-enter new password:"
send "${NEW_PWD}\r"
expect "Change the password for root ?"
send "n\r"
expect "Remove anonymous users?"
send "y\r"
expect "Disallow root login remotely?"
send "n\r"
expect "Remove test database and access to it?"
send "y\r"
expect "Reload privilege tables now?"
send "y\r"
expect eof
EOF

# -------------------------------
# 九、创建远程 root 账户
# -------------------------------
echo "👤 创建远程 root 用户..."
mysql -uroot -p"${NEW_PWD}" --connect-expired-password <<SQL
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${NEW_PWD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

# -------------------------------
# 十、验证安装
# -------------------------------
echo "🧩 验证 MySQL 连接..."
mysql -uroot -p"${NEW_PWD}" -e "SELECT VERSION(); SHOW DATABASES;"

echo "🎉 MySQL 8 安装完成！"
echo "🔑 登录方式： mysql -u root -p"
