#!/bin/bash

# almalinux 安装 Docker

# 1. 安装依赖
sudo dnf install -y dnf-plugins-core
# 2. 添加 Docker 仓库
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 3. 安装 Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# 4. 启动并启用 Docker
sudo systemctl start docker
sudo systemctl enable docke

# 下载，执行脚本
wget https://gitee.com/attacker/All-In-One-Ops/raw/master/2.docker/docker-install.sh
bash docker-install.sh