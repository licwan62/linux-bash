#!/bin/bash

# 安装nacos服务 
cat <<EOF > docker-compose-nacos.yml 
services:
  nacos:
    image: opsx-registry.cn-hangzhou.cr.aliyuncs.com/base/nacos-server:v2.1.2
    container_name: nacos
    restart: always
    ports:
      - "8848:8848"
      - "9555:9555"
      - "9848:9848"
    environment:
      - PREFER_HOST_MODE=nacos
      - MODE=standalone
    volumes:
      - /data/nacos/data:/home/nacos/data
      - /data/nacos/logs:/home/nacos/logs
EOF

docker-compose -f docker-compose-nacos.yml up -d