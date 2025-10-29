#!/bin/bash

# 安装git 
yum install git -y 
 
# 安装jenkins 

#!/bin/bash
###
# @Author: Logan.Li
# @Date: 2025-09-05 10:26:09
# @LastEditTime: 2025-09-05 13:43:36
# @Description: Jenkins CI/CD服务安装脚本
# @支持系统: RHEL/CentOS/Rocky/AlmaLinux/Amazon Linux 2/Amazon Linux 2023/Debian/Ubuntu
###
# curl -s https://gitee.com/attacker/All-In-One-Ops/raw/master/1.scripts/services/jenkins.sh | bash

# 基础设置
set -e  # 遇到错误立即退出
# set -x  # 调试模式，取消注释可查看详细执行过程

# 路径定义
DOWNLOAD_DIR="/usr/local/src"    # 下载包存放路径
INSTALL_DIR="/opt"               # 服务安装路径  
ENV_DIR="/usr/local"             # 环境依赖路径

# 简洁输出函数
info() { echo -e "\e[34m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1" >&2; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }

# 检查是否为root权限
check_root() {
    if [ $(id -u) -ne 0 ]; then
        error "### This script must be run as root !!!"
        exit 1
    fi
}

# 检查并安装必要命令
check_and_install_command() {
    local cmd="$1"
    local package="$2"
    
    info "检查命令: $cmd"
    if ! command -v "$cmd" &> /dev/null; then
        warn "命令 $cmd 未安装，正在安装 $package..."
        if command -v yum &> /dev/null; then
            yum install -y "$package"
        elif command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y "$package"
        else
            error "无法确定包管理器，请手动安装: $package"
            return 1
        fi
        
        # 再次检查
        if ! command -v "$cmd" &> /dev/null; then
            error "安装 $package 失败"
            return 1
        else
            success "成功安装并验证: $cmd"
        fi
    else
        success "命令检查通过: $cmd"
    fi
}

# 检查并安装依赖
install_dependency() {
    local name="$1"
    local check_cmd="$2"
    local install_url="$3"
    
    info "检查 $name..."
    if command -v "$check_cmd" &> /dev/null; then
        success "$name 已安装"
        return 0
    fi
    
    warn "$name 未安装，开始安装..."
    info "下载安装脚本: $install_url"
    
    # 添加超时和错误处理
    if curl -m 30 -s "$install_url" | bash; then
        success "$name 安装完成"
    else
        error "$name 安装失败，请检查网络连接"
        return 1
    fi
}

# 服务管理
service_action() {
    local action="$1"
    local service="$2"
    
    info "执行: systemctl $action $service"
    if systemctl "$action" "$service"; then
        success "服务操作成功: $action $service"
    else
        error "服务操作失败: $action $service"
        return 1
    fi
}

# 检查系统类型
check_system() {
    # 检查 Amazon Linux (基于 RHEL)
    if [[ -f /etc/os-release ]] && grep -q "Amazon Linux" /etc/os-release; then
        echo "rhel"
    # 检查 RHEL/CentOS/Rocky/AlmaLinux
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    # 检查 Debian/Ubuntu
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        error "不支持的操作系统"
        info "当前系统信息:"
        if [[ -f /etc/os-release ]]; then
            cat /etc/os-release
        fi
        exit 1
    fi
}

# 安装Jenkins仓库和密钥
setup_jenkins_repo() {
    local system_type=$(check_system)
    
    info "配置Jenkins官方仓库..."
    
    if [[ "$system_type" == "rhel" ]]; then
        # RHEL/CentOS/Amazon Linux系统
        info "配置RHEL/CentOS/Amazon Linux Jenkins仓库"
        
        # 确保wget可用
        if ! command -v wget &> /dev/null; then
            info "安装wget..."
            yum install -y wget
        fi
        
        wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
        rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
        success "Jenkins仓库配置完成"
    elif [[ "$system_type" == "debian" ]]; then
        # Debian/Ubuntu系统
        info "配置Debian/Ubuntu Jenkins仓库"
        curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
        echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
        apt-get update
        success "Jenkins仓库配置完成"
    fi
}

# 安装Jenkins
install_jenkins() {
    local system_type=$(check_system)
    
    info "开始安装Jenkins..."
    
    if [[ "$system_type" == "rhel" ]]; then
        # RHEL/CentOS/Amazon Linux系统
        yum install -y fontconfig jenkins
    elif [[ "$system_type" == "debian" ]]; then
        # Debian/Ubuntu系统
        apt-get install -y fontconfig openjdk-17-jre jenkins
    fi
    
    success "Jenkins安装完成"
}

# 安装Jenkins专用JDK17（不配置系统环境变量）
install_jdk17_for_jenkins() {
    info "安装Jenkins专用JDK17..."
    
    local JDK17_DIR="/data/jdk-17"
    mkdir -p "$JDK17_DIR"
    cd "$JDK17_DIR" || exit 1
    
    # 判断是否为中国地区并选择下载源
    local JDK17_URL
    local JDK17_FILE
    
    if is_china_region; then
        JDK17_URL="https://repo.huaweicloud.com/openjdk/17/openjdk-17_linux-x64_bin.tar.gz"
        JDK17_FILE="openjdk-17_linux-x64_bin.tar.gz"
        info "使用华为云镜像源下载JDK17"
    else
        JDK17_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10+7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz"
        JDK17_FILE="OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz"
        info "使用官方GitHub源下载JDK17"
    fi
    
    # 下载JDK17
    if [ ! -f "$JDK17_FILE" ]; then
        info "下载JDK17安装包..."
        if wget --timeout=60 --tries=3 -O "$JDK17_FILE" "$JDK17_URL"; then
            success "JDK17下载成功"
        else
            error "JDK17下载失败"
            return 1
        fi
    fi
    
    # 解压JDK17
    info "解压JDK17到$JDK17_DIR"
    tar -xzf "$JDK17_FILE" -C "$JDK17_DIR" --strip-components=1
    
    if [ ! -x "$JDK17_DIR/bin/java" ]; then
        error "JDK17解压失败"
        return 1
    fi
    
    success "Jenkins专用JDK17安装完成: $JDK17_DIR"
}

# 判断是否为中国地区
is_china_region() {
    if command -v curl &> /dev/null; then
        local country=$(curl -sSL --connect-timeout 3 https://ipapi.co/country/ 2>/dev/null | tr -d '\n\r ')
        if [ "$country" = "CN" ]; then
            return 0
        fi
    fi
    return 1
}

# 配置Jenkins使用专用JDK17启动
configure_jenkins() {
    info "配置Jenkins服务使用专用JDK17..."
    
    # 创建Jenkins工作目录
    mkdir -p /var/lib/jenkins
    chown root:root /var/lib/jenkins
    
    local system_type=$(check_system)
    local JDK17_DIR="/data/jdk-17"
    
    if [[ "$system_type" == "rhel" ]]; then
        # RHEL/CentOS/Amazon Linux系统配置
        if [[ -f /etc/sysconfig/jenkins ]]; then
            info "配置Jenkins以root用户运行，使用专用JDK17..."
            # 备份原配置
            cp /etc/sysconfig/jenkins /etc/sysconfig/jenkins.backup
            
            # 修改Jenkins运行用户为root
            sed -i 's/JENKINS_USER="jenkins"/JENKINS_USER="root"/' /etc/sysconfig/jenkins
            sed -i 's/JENKINS_GROUP="jenkins"/JENKINS_GROUP="root"/' /etc/sysconfig/jenkins
            
            # 设置Jenkins专用JDK17
            if grep -q "^JENKINS_JAVA_CMD=" /etc/sysconfig/jenkins; then
                sed -i "s|^JENKINS_JAVA_CMD=.*|JENKINS_JAVA_CMD=\"$JDK17_DIR/bin/java\"|" /etc/sysconfig/jenkins
            else
                echo "JENKINS_JAVA_CMD=\"$JDK17_DIR/bin/java\"" >> /etc/sysconfig/jenkins
            fi
            
            # Jenkins服务专用Java选项
            if grep -q "^JENKINS_JAVA_OPTIONS=" /etc/sysconfig/jenkins; then
                sed -i "s|^JENKINS_JAVA_OPTIONS=.*|JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Djava.home=$JDK17_DIR\"|" /etc/sysconfig/jenkins
            else
                echo "JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Djava.home=$JDK17_DIR\"" >> /etc/sysconfig/jenkins
            fi
            
            success "RHEL/CentOS/Amazon Linux Jenkins专用JDK17配置完成"
        fi
    elif [[ "$system_type" == "debian" ]]; then
        # Debian/Ubuntu系统配置
        if [[ -f /etc/default/jenkins ]]; then
            info "配置Jenkins以root用户运行，使用专用JDK17..."
            # 备份原配置
            cp /etc/default/jenkins /etc/default/jenkins.backup
            
            # 修改Jenkins运行用户为root
            sed -i 's/JENKINS_USER=jenkins/JENKINS_USER=root/' /etc/default/jenkins
            sed -i 's/JENKINS_GROUP=jenkins/JENKINS_GROUP=root/' /etc/default/jenkins
            
            # 设置Jenkins专用JDK17
            if grep -q "^JENKINS_JAVA_CMD=" /etc/default/jenkins; then
                sed -i "s|^JENKINS_JAVA_CMD=.*|JENKINS_JAVA_CMD=\"$JDK17_DIR/bin/java\"|" /etc/default/jenkins
            else
                echo "JENKINS_JAVA_CMD=\"$JDK17_DIR/bin/java\"" >> /etc/default/jenkins
            fi
            
            # Jenkins服务专用Java选项
            if grep -q "^JENKINS_JAVA_OPTIONS=" /etc/default/jenkins; then
                sed -i "s|^JENKINS_JAVA_OPTIONS=.*|JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Djava.home=$JDK17_DIR\"|" /etc/default/jenkins
            else
                echo "JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Djava.home=$JDK17_DIR\"" >> /etc/default/jenkins
            fi
            
            success "Debian/Ubuntu Jenkins专用JDK17配置完成"
        fi
    fi
    
    # 配置systemd服务使用专用JDK17（推荐方式）
    if [[ -f /lib/systemd/system/jenkins.service ]] || [[ -f /usr/lib/systemd/system/jenkins.service ]]; then
        local service_file=""
        if [[ -f /lib/systemd/system/jenkins.service ]]; then
            service_file="/lib/systemd/system/jenkins.service"
        else
            service_file="/usr/lib/systemd/system/jenkins.service"
        fi
        
        info "配置systemd服务使用专用JDK17: $service_file"
        cp "$service_file" "$service_file.backup"
        
        # 创建Jenkins服务专用的JDK17配置
        mkdir -p /etc/systemd/system/jenkins.service.d
        cat > /etc/systemd/system/jenkins.service.d/jdk17.conf << EOF
[Service]
# Jenkins启动专用JDK17配置（不影响系统环境变量）
Environment="JAVA_HOME=$JDK17_DIR"
Environment="PATH=$JDK17_DIR/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
User=root
Group=root
ExecStart=
ExecStart=$JDK17_DIR/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war --webroot=/var/cache/jenkins/war --httpPort=8080
EOF
        
        systemctl daemon-reload
        success "systemd服务专用JDK17配置完成"
    fi
    
    success "Jenkins配置完成（运行用户：root，专用JDK17：$JDK17_DIR）"
}

# 获取初始密码
get_initial_password() {
    info "等待Jenkins启动..."
    sleep 10
    
    if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
        local password=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
        success "Jenkins安装成功！"
        echo ""
        echo "========================================="
        echo "Jenkins访问信息："
        echo "URL: http://$(hostname -I | awk '{print $1}'):8080"
        echo "初始管理员密码: $password"
        echo "========================================="
        echo "Jenkins配置说明："
        echo "✓ Jenkins服务使用专用JDK17启动: /data/jdk-17"
        echo "✓ 系统环境变量未被修改，保持原有配置"
        echo "✓ 如需配置Job使用其他JDK版本，请在Jenkins管理界面配置"
        echo "========================================="
        echo ""
        info "请使用上述信息访问Jenkins并完成初始化设置"
    else
        warn "初始密码文件未找到，请检查Jenkins启动状态"
    fi
}

# 主函数
main() {
    info "开始安装Jenkins CI/CD服务..."
    
    # 直接开始安装，跳过权限检查
    info "开始Jenkins安装流程..."
    
    info "检查必要命令..."
    # 简化命令检查，避免复杂函数调用
    if ! command -v curl &> /dev/null; then
        warn "安装curl..."
        yum install -y curl
    fi
    success "curl命令可用"
    
    if ! command -v systemctl &> /dev/null; then
        error "systemctl不可用，请检查systemd"
        exit 1
    fi
    success "systemctl命令可用"
    
    info "检查系统类型..."
    local system_type=$(check_system)
    info "检测到系统类型: $system_type"
    
    # 检查并安装Jenkins专用JDK17
    info "开始检查Jenkins专用JDK17依赖..."
    
    # 检查JDK17是否已安装在指定目录
    if [[ -x /data/jdk-17/bin/java ]]; then
        local java_version=$(/data/jdk-17/bin/java -version 2>&1 | head -n1)
        success "Jenkins专用JDK17已安装: $java_version"
        info "跳过JDK17安装，继续Jenkins配置..."
    else
        warn "Jenkins专用JDK17未安装，开始安装..."
        info "JDK17安装过程包括："
        info "1. 检测网络环境和镜像源"
        info "2. 下载JDK17安装包（约200MB，显示进度条）"
        info "3. 解压到/data/jdk-17目录"
        info "4. 配置Jenkins服务专用JDK"
        info ""
        info "开始安装Jenkins专用JDK17，请耐心等待..."
        
        # 调用JDK17安装脚本，但不配置系统环境变量
        install_jdk17_for_jenkins
        
        # 验证JDK17是否安装成功
        if [[ -x /data/jdk-17/bin/java ]]; then
            local java_version=$(/data/jdk-17/bin/java -version 2>&1 | head -n1)
            success "Jenkins专用JDK17安装成功: $java_version"
        else
            error "Jenkins专用JDK17安装失败，无法继续安装Jenkins"
            exit 1
        fi
    fi
    
    # 检查Jenkins是否已安装
    if systemctl is-active --quiet jenkins 2>/dev/null; then
        success "Jenkins已安装并运行中"
        systemctl status jenkins --no-pager
        exit 0
    fi
    
    # 安装Jenkins
    setup_jenkins_repo
    install_jenkins
    configure_jenkins
    
    # 启动Jenkins服务
    service_action "enable" "jenkins"
    service_action "start" "jenkins"
    
    # 获取初始密码
    get_initial_password
    
    success "Jenkins安装和配置完成！"
}

# 执行主函数
main "$@"


# 获取密码 
cat /var/lib/jenkins/secrets/initialAdminPassword