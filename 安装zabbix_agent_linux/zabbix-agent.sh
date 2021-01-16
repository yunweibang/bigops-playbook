#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

#awk里的$前必须加转义
if [ ! -z "$(ps aux|grep 'zabbix_agentd'|grep -v grep)" ];then
    ps aux|grep 'zabbix_agentd'|grep -v grep|awk '{print \$2}'|xargs sudo kill -9 >/dev/null 2>&1
fi

if ! hash systemctl 2>/dev/null;then 
    sudo mv -f /etc/zabbix/zabbix-agent.init /etc/init.d/zabbix-agent.init
    sudo chmod 777 /etc/init.d/zabbix-agent.init
    sudo chkconfig zabbix-agent on
    sudo service zabbix-agent start
fi

if hash systemctl 2>/dev/null;then 
    sudo mv -f /etc/zabbix/zabbix-agent.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable zabbix-agent
    sudo systemctl start zabbix-agent
fi


      