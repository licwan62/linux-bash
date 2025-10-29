#!/bin/bash

source _install_nginx_stylish_fonts.sh || echo 'style not found'

# 可修改参数
CONF_NAME="nginx.conf"
NGINX_VER="nginx-1.26.3"
SRC_DIR="/usr/local/src"
INSTALL_DIR="/usr/local"
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
CODE_ROOT="${SRC_DIR}/${NGINX_VER}"

header " Nginx 自动安装脚本 (v1.26.3)"

# 安装依赖
yum install -y gcc pcre pcre-devel zlib-devel openssl openssl-devel

# 创建用户和组，作为nginx服务中间账号
if id nginx &>/dev/null; then
    warn nginx用户已存在,无需创建创建,故跳过
else
    groupadd nginx
    useradd -g nginx -s /sbin/nologin -M nginx
fi

# 下载nginx源代码目录
if [ -e "${CODE_ROOT}" ]; then
    warn "检测到 '${NGINX_VER}' 目录, 似乎已安装了nginx源代码,故跳过"
else
    step 下载nginx中
    if [ ! -e "${CODE_ROOT}.tar.gz" ]; then
        wget "https://nginx.org/download/${NGINX_VER}.tar.gz" -P "${SRC_DIR}"
    fi

    tar -zxf "${CODE_ROOT}.tar.gz" -C "${SRC_DIR}"
    
    if [ ! -e "${CODE_ROOT}" ]; then
        error Nginx下载解压失败,安装程序退出
        exit
    else
        success Nginx下载并解压成功,源代码已就位
    fi
fi


# 设置安装参数：安装位置、中间账号
step 正在编译Nginx源代码

cd "${CODE_ROOT}" || { echo "${CODE_ROOT}不存在" && exit1; }
./configure \
--prefix=${INSTALL_DIR}/nginx \
--user=nginx \
--group=nginx \
--with-http_ssl_module \
--with-pcre \
--with-http_stub_status_module \
--with-http_gzip_static_module \
--with-stream \
--with-stream_ssl_module \
--with-http_realip_module

# 编译安装
make && make install
if [ $? -eq 0 ]; then 
    success "编译成功!"
else 
    error "编译失败!"
    exit 1
fi

# 创建配置文件目录并修改配置文件
mkdir "${INSTALL_DIR}/nginx/conf/conf.d"
rm -rf "${INSTALL_DIR}/nginx/conf/nginx.conf"
cp "${SCRIPT_DIR}/${CONF_NAME}" "${INSTALL_DIR}/nginx/conf/${CONF_NAME}"
ln -s ${INSTALL_DIR}/nginx/sbin/nginx /usr/bin/nginx
success 配置文件已调试