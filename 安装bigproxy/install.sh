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

if [ -f /opt/bigops/bigproxy/bigproxy.properties ];then
  cp -f /opt/bigops/bigproxy/bigproxy.properties /opt/bigops/bigproxy/config/
fi

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

if [ -f /opt/bigops/bigproxy/whitelist ];then
  cp -f /opt/bigops/bigproxy/whitelist /opt/bigops/bigproxy/config/
fi

if hash systemctl 2>/dev/null;then
  sudo cp -f /opt/bigops/bigproxy/bigproxy.service /usr/lib/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable bigproxy
  sudo systemctl restart bigproxy
fi

