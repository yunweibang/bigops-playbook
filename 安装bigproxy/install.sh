#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

alias cp=cp
alias mv=mv

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

# sudo rpm -ivh --force perl-DBD-MySQL-*.rpm >/dev/null 2>&1
# sudo rpm -ivh --force libev-*.rpm >/dev/null 2>&1
# sudo rpm -ivh --force percona-xtrabackup-8*.rpm >/dev/null 2>&1
# sudo mv -f /usr/bin/xtrabackup /usr/bin/xtrabackup8 >/dev/null 2>&1

# sudo rpm -e percona-xtrabackup-80-8.0.23-16.1.el7.x86_64 >/dev/null 2>&1
# sudo rpm -ivh --force percona-xtrabackup-2*.rpm >/dev/null 2>&1

docker stop bigproxy >/dev/null 2>&1
docker rm -f bigproxy >/dev/null 2>&1
docker rmi bigproxy:latest >/dev/null 2>&1

chmod +x /opt/bigops/bigproxy/*.sh /opt/bigops/bigproxy/*.jar

mkdir -p /opt/bigops/bigproxy/config >/dev/null 2>&1
mkdir /opt/bigops/bigproxy/hosts >/dev/null 2>&1
mkdir /opt/bigops/bigproxy/hostinfo_temp >/dev/null 2>&1
mkdir /opt/bigops/bigproxy/hostmon_temp >/dev/null 2>&1
mkdir /opt/bigops/bigproxy/logs >/dev/null 2>&1
mkdir /opt/bigops/bigproxy/temp >/dev/null 2>&1
mkdir /opt/bigops/bigproxy/config_file/ >/dev/null 2>&1

if [ -f /opt/bigops/bigproxy/whitelist ];then
  mv -f /opt/bigops/bigproxy/whitelist /opt/bigops/bigproxy/config/
fi

if [ -f /opt/bigops/bigproxy/bigproxy.properties ];then
  mv -f /opt/bigops/bigproxy/bigproxy.properties /opt/bigops/bigproxy/config/
  jvm_option="$(grep ^jvm_option= /opt/bigops/bigproxy/config/bigproxy.properties|awk -F= '{print $2}'|sed 's/"//g')"
  sed -i 's/jvm_option/'"${jvm_option}"'/g' /opt/bigops/bigproxy/start.sh
fi

if hash systemctl 2>/dev/null;then
  sudo cp -f /opt/bigops/bigproxy/bigproxy.service /usr/lib/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable bigproxy
  sudo systemctl restart bigproxy
fi

