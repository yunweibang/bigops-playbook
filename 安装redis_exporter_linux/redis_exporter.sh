#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

cd /opt/exporter/
tar zxvf redis_exporter-v1.15.0.linux-amd64.tar.gz
cp -f redis_exporter-v1.15.0.linux-amd64/redis_exporter /opt/exporter/

#判断redis密码是否为空
if [ ! -z "$2" ];then
    sed -i "s#redis_addr#"$1"#g" /opt/exporter/redis_exporter.init
    sed -i "s#reids_pass#"$2"#g" /opt/exporter/redis_exporter.init
    sed -i "s#redis_addr#"$1"#g" /opt/exporter/redis_exporter.service
    sed -i "s#reids_pass#"$2"#g" /opt/exporter/redis_exporter.service
else
    sed -i "s#redis_addr#"$1"#g" /opt/exporter/redis_exporter.init
    sed -i "s#-redis.password reids_pass##g" /opt/exporter/redis_exporter.init
    sed -i "s#redis_addr#"$1"#g" /opt/exporter/redis_exporter.service
    sed -i "s#-redis.password reids_pass##g" /opt/exporter/redis_exporter.service
fi

if ! hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/redis_exporter.init /etc/init.d/redis_exporter
    sudo chmod 777 /etc/init.d/redis_exporter
    sudo chkconfig redis_exporter on
    sudo service redis_exporter restart
fi

if hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/redis_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable redis_exporter
    sudo systemctl restart redis_exporter
fi


