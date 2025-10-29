#!/bin/bash

# 安装redis

Deploy(){
###
# @Author: Logan.Li
# @Gitee: https://gitee.com/attacker
# @email: admin@attacker.club
# @Date: 2025-04-25 11:22:51
# @LastEditTime: 2025-09-09 18:46:34
# @Description: 
###
        yum install redis -y
        sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf  #监听所有地址
        sed -i 's/daemonize no/daemonize yes/' /etc/redis.conf   # 是否以守护进程方式启动
        sed -i 's/timeout 0/timeout 30/' /etc/redis.conf  # 客户端连接的超时时间,单位为秒,超时后会关闭连接，0永不超时
        sed -i 's/tcp-keepalive 0/tcp-keepalive 60/' /etc/redis.conf #
        #sed -i 's/# maxclients 10000/maxclients 100000/' /etc/redis.conf # 默认客户端最大连接数1w
        sed -i '/^#/d;/^$/d'  /etc/redis.conf # 删除废话

        echo 'slowlog-log-slower-than 1000000' >> /etc/redis.conf   # 记录超过1秒的操作
        echo 'slowlog-max-len 50' >> /etc/redis.conf  # 记录50个

        sysctl -w vm.overcommit_memory=1

        # echo loglevel warning
        # logfile "/var/log/redis.log"
}

cat >> /etc/sysctl.conf <<EOF
# Set up for Redis
vm.overcommit_memory = 1 # 设置0的话，Linux的OOM机制会在内存不足时触发自动Kill进程点数过高的进程
EOF
systemctl enable redis
systemctl start redis
# 启动服务

# set_passwd(){
#         read -p 'set password:' pwd
#         grep requirepass /etc/redis.conf || echo "requirepass ${pwd}"  >>/etc/redis.conf
#         # 授权 ；redis-cli  -a xxxx 登入
#         systemctl restart redis
# }
which  redis-cli  &> /dev/null &&  echo "redis-cli 已安装"|| Deploy


bash redis.sh