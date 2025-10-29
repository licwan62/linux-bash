#!/bin/bash

# 安装git 
yum install git -y 
 
# 安装jenkins 
curl -s https://gitee.com/attacker/All-In-One-Ops/raw/master/1.scripts/services/jenkins.sh | bash

# 获取密码 
cat /var/lib/jenkins/secrets/initialAdminPassword