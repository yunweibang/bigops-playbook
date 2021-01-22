#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

cd /opt/exporter/
tar zxvf elasticsearch_exporter-1.1.0.linux-amd64.tar.gz
cp -f elasticsearch_exporter-1.1.0.linux-amd64/elasticsearch_exporter /opt/exporter/

sed -i "s#es_user#$1#g" /opt/exporter/elasticsearch_exporter.init
sed -i "s#es_pass#$2#g" /opt/exporter/elasticsearch_exporter.init
sed -i "s#es_ip#$3#g" /opt/exporter/elasticsearch_exporter.init
sed -i "s#es_port#$4/g" /opt/exporter/elasticsearch_exporter.init

sed -i "s#es_user#$1#g" /opt/exporter/elasticsearch_exporter.service
sed -i "s#es_pass#$2#g" /opt/exporter/elasticsearch_exporter.service
sed -i "s#es_ip#$3#g" /opt/exporter/elasticsearch_exporter.service
sed -i "s#es_port#$4#g" /opt/exporter/elasticsearch_exporter.service

if ! hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/elasticsearch_exporter.init /etc/init.d/elasticsearch_exporter
    sudo chmod 777 /etc/init.d/elasticsearch_exporter
    sudo chkconfig elasticsearch_exporter on
    sudo service elasticsearch_exporter restart
fi

if hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/elasticsearch_exporter.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable elasticsearch_exporter
    sudo systemctl restart elasticsearch_exporter
fi

