#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

alias cp=cp

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

docker stop bigproxy >/dev/null 2>&1
docker rm -f bigproxy >/dev/null 2>&1
docker rmi bigproxy:latest >/dev/null 2>&1

chmod +x /opt/bigops/bigproxy/*.sh /opt/bigops/bigproxy/*.jar


if [ ! -d /opt/bigops/bigproxy/hostinfo_temp ];then
	mkdir /opt/bigops/bigproxy/hostinfo_temp
fi

if [ ! -d /opt/bigops/bigproxy/hostmon_temp ];then
	mkdir /opt/bigops/bigproxy/hostmon_temp
fi

if [ ! -d /opt/bigops/bigproxy/logs ];then
	mkdir /opt/bigops/bigproxy/logs
fi

if [ ! -d /opt/bigops/bigproxy/temp ];then
	mkdir /opt/bigops/bigproxy/temp
fi

if [ -f /opt/bigops/bigproxy/bigproxy.properties ];then
  mv -f /opt/bigops/bigproxy/bigproxy.properties /opt/bigops/bigproxy/config/
fi

if [ -f /opt/bigops/bigproxy/whitelist ];then
  mv -f /opt/bigops/bigproxy/whitelist /opt/bigops/bigproxy/config/
fi

if [ ! -z "$2" ];then
  sed -i "s/Xms4G/Xms"$2"/g" /opt/bigops/bigproxy/start.sh
  sed -i "s/Xmx4G/Xmx"$2"/g" /opt/bigops/bigproxy/start.sh
else
  echo "缺少第二个参数"
  exit
fi

if [ ! -z "$1" ];then
  sed -i "s/log_status=.*/log_status="$1"/g" /opt/bigops/bigproxy/config/bigproxy.properties
fi


if hash systemctl 2>/dev/null;then
  sudo cp -f /opt/bigops/bigproxy/bigproxy.service /usr/lib/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable bigproxy
  sudo systemctl restart bigproxy
fi

