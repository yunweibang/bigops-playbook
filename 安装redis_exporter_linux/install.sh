#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

ps aux|grep redis_exporter|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null

cd /opt/exporter/
tar zxvf redis_exporter-v1.15.0.linux-amd64.tar.gz
if [ ! -d /opt/exporter/redis_exporter ];then
    mkdir /opt/exporter/redis_exporter
fi
cp -f redis_exporter-v1.15.0.linux-amd64/redis_exporter /opt/exporter/redis_exporter/
sudo chmod -R 777 /opt/exporter/redis_exporter/

sed -i "s/localhost:6379/"$1"/g" /opt/exporter/redis_exporter.init
sed -i "s/localhost:6379/"$1"/g" /opt/exporter/redis_exporter.service
if [ -z "$2" ];then
    sed -i "s/ -redis.password 123456//g" /opt/exporter/redis_exporter.init
    sed -i "s/ -redis.password 123456//g" /opt/exporter/redis_exporter.service
else
    sed -i "s/-redis.password 123456/-redis.password "$2"/g" /opt/exporter/redis_exporter.init
    sed -i "s/-redis.password 123456/-redis.password "$2"/g" /opt/exporter/redis_exporter.service
fi

if ! hash systemctl 2>/dev/null;then 
    if [ ! -f /usr/sbin/daemonize ];then
        sudo rpm -ivh daemonize-1.7.3-7.el6.x86_64.rpm
    fi
    sudo cp -f /opt/exporter/redis_exporter.init /etc/init.d/redis_exporter
    sudo chmod 777 /etc/init.d/redis_exporter
    sudo chkconfig redis_exporter on
    sudo service redis_exporter start
fi

if hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/redis_exporter.service /usr/lib/systemd/system/
    sudo systemctl enable redis_exporter
    sudo systemctl start redis_exporter
fi


