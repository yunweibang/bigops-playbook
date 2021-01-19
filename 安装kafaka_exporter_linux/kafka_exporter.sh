#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

cd /opt/exporter/
tar zxvf kafka_exporter-1.2.0.linux-amd64.tar.gz
cp -f kafka_exporter-1.2.0.linux-amd64/kafka_exporter /opt/exporter/

sed -i "s#kafka_ip#$1#g" /opt/exporter/elasticsearch_exporter.init
sed -i "s#kafka_port#$2#g" /opt/exporter/elasticsearch_exporter.init

sed -i "s#kafka_ip#$1#g" /opt/exporter/elasticsearch_exporter.service
sed -i "s#kafka_port#$2#g" /opt/exporter/elasticsearch_exporter.service


if ! hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/kafka_exporter.init /etc/init.d/kafka_exporter
    sudo chmod 777 /etc/init.d/kafka_exporter
    sudo chkconfig kafka_exporter on
    sudo service kafka_exporter restart
fi

if hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/kafka_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable kafka_exporter
    sudo systemctl restart kafka_exporter
fi


