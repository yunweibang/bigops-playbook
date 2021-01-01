#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

ps aux|grep mysqld_exporter|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null

cd /opt/exporter/
tar zxvf mysqld_exporter-0.12.1.linux-amd64.tar.gz
if [ ! -d /opt/exporter/mysqld_exporter ];then
    mkdir /opt/exporter/mysqld_exporter
fi
cp -f mysqld_exporter-0.12.1.linux-amd64/mysqld_exporter /opt/exporter/mysqld_exporter/
sudo chmod -R 777 /opt/exporter/mysqld_exporter/

echo [client] > /opt/exporter/mysqld_exporter/"$4"
echo host="$1" >> /opt/exporter/mysqld_exporter/"$4"
echo user="$2" >> /opt/exporter/mysqld_exporter/"$4"
echo password="$3" >> /opt/exporter/mysqld_exporter/"$4"

if ! hash systemctl 2>/dev/null;then 
	if [ ! -f /usr/sbin/daemonize ];then
    	sudo rpm -ivh daemonize-1.7.3-7.el6.x86_64.rpm
	fi
    sudo cp -f /opt/exporter/mysqld_exporter.init /etc/init.d/mysqld_exporter
    sudo chmod 777 /etc/init.d/mysqld_exporter
    sudo chkconfig mysqld_exporter on
    sudo service mysqld_exporter start
fi

if hash systemctl 2>/dev/null;then 
    sudo cp -f /opt/exporter/mysqld_exporter.service /usr/lib/systemd/system/
    sudo systemctl enable mysqld_exporter
    sudo systemctl start mysqld_exporter
fi


