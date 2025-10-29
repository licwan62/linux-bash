#!/bin/bash

dataDir="/opt/docker-data/mysql"
yum remove mariadb* -y # 卸载mariadb
rpm -ivh https://repo.mysql.com/mysql80-community-release-el7.rpm
yum install mysql-community-client -y # 安装mysql客户端

password=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)
docker run \
    --restart always \
    -d -p 3306:3306 --name mysql \
    -v $dataDir:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=$password \
    mysql:8
echo "passwod: $password" >mysql.txt


bash mysql8.sh