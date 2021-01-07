#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

if [ -d /opt/exporter/node_exporter ];then
    rm -rf /opt/exporter/node_exporter
fi

ps aux|grep node_exporter|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null

cd /opt/exporter/
tar zxvf node_exporter-0.18.1.linux-amd64.tar.gz
cp -f node_exporter-0.18.1.linux-amd64/node_exporter /opt/exporter/
if [ ! -d /opt/exporter/key/ ];then
    mkdir /opt/exporter/key/
fi
sudo mv -f /opt/exporter/syskey.sh /opt/exporter/key/
sudo mv -f /opt/exporter/userkey.sh /opt/exporter/key/
sudo chmod +x /opt/exporter/key/*

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


      