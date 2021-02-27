#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

cd /opt/exporter/
tar zxvf node_exporter-1.1.0.linux-amd64.tar.gz
cp -f node_exporter-1.1.0.linux-amd64/node_exporter /opt/exporter/

sudo chmod 777 /opt/exporter/mpstat 

if [[ -f "/opt/exporter/mpstat" ]] && [[ ! -f "/bin/mpstat" ]];then
    sudo cp -pf /opt/exporter/mpstat /bin/
fi

cp -f node_exporter-1.1.0.linux-amd64/node_exporter /opt/exporter/

if [ ! -d /opt/exporter/key/ ];then
    mkdir /opt/exporter/key/
fi

if [ -f "/opt/exporter/syskey.sh" ];then
    mv -f /opt/exporter/syskey.sh /opt/exporter/key/
fi

if [ -f "/opt/exporter/userkey.sh" ];then
    mv -f /opt/exporter/userkey.sh /opt/exporter/key/
fi

chmod 777 /opt/exporter/key/* 

timeout 50 /bin/bash /opt/exporter/key/*key.sh


if ! hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/node_exporter.init /etc/init.d/node_exporter
    sudo chmod 777 /etc/init.d/node_exporter
    sudo chkconfig node_exporter on
    sudo service node_exporter restart
fi

if hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/node_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter
    sudo systemctl restart node_exporter
fi
