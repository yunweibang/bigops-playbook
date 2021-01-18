#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

#awk里的$前必须加转义
if [ ! -z "$(ps aux|grep '/opt/exporter/oracle_exporter'|grep -v grep)" ];then
    ps aux|grep '/opt/exporter/oracle_exporter'|grep -v grep|awk '{print \$2}'|xargs sudo kill -9 >/dev/null 2>&1
fi

cd /opt/exporter/
tar zxvf oracle_exporter-1.0.0-RC7.linux-amd64.tar.gz
cp -f oracle_exporter-1.0.0-RC7.linux-amd64/oracle_exporter /opt/exporter/

sed -i "s#oracle_user#$1#g" /opt/exporter/oracle_exporter.init
sed -i "s#oracle_pass#$2#g" /opt/exporter/oracle_exporter.init
sed -i "s#oracle_host#$3#g" /opt/exporter/oracle_exporter.init
sed -i "s#oracle_port#$4#g" /opt/exporter/oracle_exporter.init
sed -i "s#oracle_service#$5#g" /opt/exporter/oracle_exporter.init

sed -i "s#oracle_user#$1#g" /opt/exporter/oracle_exporter.service
sed -i "s#oracle_pass#$2#g" /opt/exporter/oracle_exporter.service
sed -i "s#oracle_host#$3#g" /opt/exporter/oracle_exporter.service
sed -i "s#oracle_port#$4#g" /opt/exporter/oracle_exporter.service
sed -i "s#oracle_service#$5#g" /opt/exporter/oracle_exporter.service


if ! hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/oracle_exporter.init /etc/init.d/oracle_exporter
    sudo chmod 777 /etc/init.d/oracle_exporter
    sudo chkconfig oracle_exporter on
    sudo service oracle_exporter start
fi

if hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/oracle_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable oracle_exporter
    sudo systemctl start oracle_exporter
fi