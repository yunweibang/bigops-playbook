#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

#awk里的$前必须加转义
if [ ! -z "$(ps aux|grep '/opt/exporter/rabbitmq_exporter'|grep -v grep)" ];then
    ps aux|grep '/opt/exporter/rabbitmq_exporter'|grep -v grep|awk '{print \$2}'|xargs sudo kill -9 >/dev/null 2>&1
fi

cd /opt/exporter/
tar zxvf rabbitmq_exporter-1.0.0-RC7.linux-amd64.tar.gz
cp -f rabbitmq_exporter-1.0.0-RC7.linux-amd64/rabbitmq_exporter /opt/exporter/

sed -i "s#RABBIT_USER=guest#RABBIT_USER=$1#g" /opt/exporter/rabbitmq_exporter.init
sed -i "s#RABBIT_PASSWORD=guest#RABBIT_PASSWORD=$2#g" /opt/exporter/rabbitmq_exporter.init
sed -i "s#OUTPUT_FORMAT=JSON#OUTPUT_FORMAT=$3#g" /opt/exporter/rabbitmq_exporter.init
sed -i "s#PUBLISH_PORT=9419#PUBLISH_PORT=$4#g" /opt/exporter/rabbitmq_exporter.init
sed -i "s#RABBIT_URL=http://localhost:15672#RABBIT_URL=$5#g" /opt/exporter/rabbitmq_exporter.init

sed -i "s#RABBIT_USER=guest#RABBIT_USER=$1#g" /opt/exporter/rabbitmq_exporter.service
sed -i "s#RABBIT_PASSWORD=guest#RABBIT_PASSWORD=$2#g" /opt/exporter/rabbitmq_exporter.service
sed -i "s#OUTPUT_FORMAT=JSON#OUTPUT_FORMAT=$3#g" /opt/exporter/rabbitmq_exporter.service
sed -i "s#PUBLISH_PORT=9419#PUBLISH_PORT=$4#g" /opt/exporter/rabbitmq_exporter.service
sed -i "s#RABBIT_URL=http://localhost:15672#RABBIT_URL=$5#g" /opt/exporter/rabbitmq_exporter.service

if ! hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/rabbitmq_exporter.init /etc/init.d/rabbitmq_exporter
    sudo chmod 777 /etc/init.d/rabbitmq_exporter
    sudo chkconfig rabbitmq_exporter on
    sudo service rabbitmq_exporter start
fi

if hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/rabbitmq_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable rabbitmq_exporter
    sudo systemctl start rabbitmq_exporter
fi