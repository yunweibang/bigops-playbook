#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

ps aux|grep redis_exporter|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null

cd /opt/exporter/
tar zxvf redis_exporter-v1.15.0.linux-amd64.tar.gz
cp -f redis_exporter-v1.15.0.linux-amd64/redis_exporter /opt/exporter/

sed -i "s/localhost:9121/"$1"/g" /opt/exporter/redis_exporter.init
sed -i "s/localhost:9121/"$1"/g" /opt/exporter/redis_exporter.service

if [ -z "$2" ];then
    sed -i "s/ -redis.password 123456//g" /opt/exporter/redis_exporter.init
    sed -i "s/ -redis.password 123456//g" /opt/exporter/redis_exporter.service
else
    sed -i "s/-redis.password 123456/-redis.password "$2"/g" /opt/exporter/redis_exporter.init
    sed -i "s/-redis.password 123456/-redis.password "$2"/g" /opt/exporter/redis_exporter.service
fi

if ! hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/redis_exporter.init /etc/init.d/redis_exporter
    sudo chmod 777 /etc/init.d/redis_exporter
    sudo chkconfig redis_exporter on
    sudo service redis_exporter start
    sudo systemctl daemon-reload
fi

if hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/redis_exporter.service /usr/lib/systemd/system/
    sudo systemctl enable redis_exporter
    sudo systemctl start redis_exporter
fi


