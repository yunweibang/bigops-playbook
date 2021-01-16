#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

#awk里的$前必须加转义
if [ ! -z "$(ps aux|grep '/opt/exporter/node_exporter'|grep -v grep)" ];then
    ps aux|grep '/opt/exporter/node_exporter'|grep -v grep|awk '{print \$2}'|xargs sudo kill -9 >/dev/null 2>&1
fi

cd /opt/exporter/
tar zxvf node_exporter-0.18.1.linux-amd64.tar.gz
cp -f node_exporter-0.18.1.linux-amd64/node_exporter /opt/exporter/

if [ ! -d /opt/exporter/key/ ];then
    mkdir /opt/exporter/key/
fi

if [ -f "/opt/exporter/syskey.sh" ];then
    mv -f /opt/exporter/syskey.sh /opt/exporter/key/
fi

if [ -f "/opt/exporter/userkey.sh" ];then
    mv -f /opt/exporter/userkey.sh /opt/exporter/key/
fi

chmod +x /opt/exporter/key/*

timeout 30 /bin/bash /opt/exporter/key/*key.sh

if ! hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/node_exporter.init /etc/init.d/node_exporter
    sudo chmod 777 /etc/init.d/node_exporter
    sudo chkconfig node_exporter on
    sudo service node_exporter start
fi

if hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/node_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
fi
