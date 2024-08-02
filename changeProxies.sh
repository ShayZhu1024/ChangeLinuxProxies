#!/bin/bash
################################
# Author: ShayZhu
# Contact: shayzhu@hotmail.com
# Version: 1.0.0
# Date: 2024-08-01
# Description:
################################
set -u
set -e 

RED='\033[31;1m'
FLASH_RED='\033[31;1;5m'
GREEN='\033[32;1m'
PLAIN='\033[0m'
YELLOW='\033[33m'
SUCCESS="${GREEN}成功${PLAIN}"
FAIL="${FLASH_RED}失败${PLAIN}"

#$1 prompt message
successMessage() {
    echo -ne "${SUCCESS} ${GREEN}$1${PLAIN} ${YELLOW}按任意键继续...${PLAIN}" && read
}

#$1 prompt message
errorMessage() {
    echo -ne "${FAIL} ${RED}$1${PLAIN} ${YELLOW}按任意键继续...${PLAIN}" && read 
}

warnMessage() {
    echo -ne "${YELLOW}注意: $1 ${PLAIN} ${YELLOW}按任意键继续...${PLAIN}" && read 
}

httpProxy=""
proxyEnvVarsFile=/etc/profile.d/proxy.sh

menus=(
    "1  设置git代理" 
    "2  取消git代理"
    "3  设置http代理环境变量(pip curl会生效)"
    "4  取消http代理环境变量"
    "5  设置apt代理"
    "6  取消apt代理"
    "0  退出"
)

#init proxy address
init() {
    echo -e "请输入http代理地址:例如: 10.0.0.1:7890"
    while true; do 
        read -r -p "例如: 10.0.0.1:7890 "  httpProxy
        curl -x $httpProxy --connect-timeout 5  www.google.com  &>/dev/null && { successMessage "代理地址有效"; break;  }  || errorMessage "代理地址无效" 
    done
}


setGitProxy() {
    git config --global http.proxy $httpProxy
    git config --global https.proxy $httpProxy
    successMessage "git代理设置成功"
}

unsetGitProxy() {
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    successMessage "git代理取消成功"
}

setEnvProxy() {
    cat > $proxyEnvVarsFile  <<EOF
export http_proxy=http://$httpProxy
export https_proxy=http://$httpProxy
EOF
    successMessage "http代理环境变量设置成功"
    warnMessage "退出脚本后请重新登录bash才能生效!"
}

unsetEnvProxy() {
    rm -rf $proxyEnvVarsFile
    successMessage "http代理环境变量取消成功"
    warnMessage "退出脚本后请重新登录bash才能生效!"
}


setAptProxy() {
    cat > /etc/apt/apt.conf.d/proxy.conf <<EOF
Acquire {
  HTTP::proxy "http://$httpProxy";
  HTTPS::proxy "http://$httpProxy";
}
EOF
}

mainProc() {
    local result=""
    read -r -p "请选择: "  result
    case "$result"  in 
        "1")
            setGitProxy
            ;;
        "2")
            unsetGitProxy
            ;;
        "3")
            setEnvProxy
            ;;
        "4")
            unsetEnvProxy
            ;;
        "5")
            setAptProxy
            ;;
        "6")
            unsetAptProxy
            ;;
        "0")
            return 1
            ;;
         *)
            warnMessage  "选择前面的数字"
            ;;
    esac
}


#$1 menus name
displayMenus() {
    local arrName=$1
    eval local items=(\"\${$arrName[@]}\")
    local item=""
    for item in "${items[@]}"; do
        echo "$item"
    done
}


#$1 procFunc $2 menusName
menuSelect() {
    local  procFunc=$1
    while true; do
        displayMenus "$2"
        if ! $procFunc ; then
            break
        fi
    done
}

init
menuSelect "mainProc"  "menus"

