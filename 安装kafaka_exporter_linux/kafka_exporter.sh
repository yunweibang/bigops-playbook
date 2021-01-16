#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

#awk里的$前必须加转义
if [ ! -z "$(ps aux|grep '/opt/exporter/kafka_exporter'|grep -v grep)" ];then
    ps aux|grep '/opt/exporter/kafka_exporter'|grep -v grep|awk '{print \$2}'|xargs sudo kill -9 >/dev/null 2>&1
fi

cd /opt/exporter/
tar zxvf kafka_exporter-1.2.0.linux-amd64.tar.gz
cp -f kafka_exporter-1.2.0.linux-amd64/kafka_exporter /opt/exporter/

if ! hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/kafka_exporter.init /etc/init.d/kafka_exporter
    sudo chmod 777 /etc/init.d/kafka_exporter
    sudo chkconfig kafka_exporter on
    sudo service kafka_exporter start
fi

if hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/kafka_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable kafka_exporter
    sudo systemctl start kafka_exporter
fi


