#!/bin/bash

wget https://l-ops.oss-cn-hangzhou.aliyuncs.com/kubectl
chmod +x kubectl
mv kubectl  /usr/bin/

# 测试
kubectl get ns