#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

ps aux|grep node_exporter|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null

cd /opt/exporter/
tar zxvf node_exporter-0.18.1.linux-amd64.tar.gz
cp -f node_exporter-0.18.1.linux-amd64/node_exporter /opt/exporter/node_exporter/
sudo mv -f /opt/exporter/syskey.sh /opt/exporter/node_exporter/key/
sudo mv -f /opt/exporter/userkey.sh /opt/exporter/node_exporter/key/
sudo chmod +x /opt/exporter/node_exporter/key/

timeout 30 /bin/bash /opt/exporter/node_exporter/key/*key.sh

if ! hash systemctl 2>/dev/null;then 
	if [ ! -f /usr/sbin/daemonize ];then
    	sudo rpm -ivh daemonize-1.7.3-7.el6.x86_64.rpm
	fi
    sudo mv -f /opt/exporter/node_exporter.init /etc/init.d/node_exporter
    sudo chmod 777 /etc/init.d/node_exporter
    sudo chkconfig node_exporter on
    sudo service node_exporter start
fi

if hash systemctl 2>/dev/null;then 
    sudo mv -f /opt/exporter/node_exporter.service /usr/lib/systemd/system/
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
fi


      