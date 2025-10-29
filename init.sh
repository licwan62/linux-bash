#!/bin/bash

#禁用selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux）
#关闭防火墙 
systemctl stop firewalld）&& systemctl disable firewalld
#历史命令显示操作时间 
sed -i '$a export HISTTIMEFORMAT="%F %T "' /etc/profile && source /etc/profile
#SSH超时时间 
echo "export TMOUT=600" >> /etc/profile
#禁止定时任务发送邮件
sed -i 's/^MAILTO=root/MAILTO=""/g' /etc/crontab

#设置最大打开文件数
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
EOF

#系统内核优化
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 20480
net.ipv4.tcp_max_syn_backlog = 20480
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_fin_timeout = 20
EOF

#减少SWAP使用
echo "0" > /proc/sys/vm/swappiness

#安装系统性能分析工具及其他：
yum -y install gcc make elinks htop iotop iftop lrzsz epel-release