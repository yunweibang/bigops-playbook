#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

alias cp=cp
alias mv=mv

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi


if [ ! -z "$6" ];then
   echo "参数错误，退出！"
   exit
fi

if [[ ! -f "$3" ]] && [[ ! -f "$4" ]];then
   echo "$3或$4文件不存在，退出！"
   exit
fi

cd /tmp

if [[ ! -d /usr/local/filebeat ]] && [[ -f /tmp/filebeat-7.11.1-linux-x86_64.tar.gz ]];then
  sudo tar zxvf filebeat-7.11.1-linux-x86_64.tar.gz
  sudo mv filebeat-7.11.1-linux-x86_64 /usr/local/filebeat
  sudo rm -f filebeat-7.11.1-linux-x86_64.tar.gz
fi

if [ ! -d /usr/local/filebeat/config/ ];then
   sudo mkdir /usr/local/filebeat/config/
fi

sudo cp -f filebeat.yml /usr/local/filebeat/config/$2.yml

#/usr/local/install.sh 实例ID 实例端口 slowlog路径 errorlog路径 logstash配置

sudo sed -i 's#bigops_id#'"$1"'#g' /usr/local/filebeat/config/$2.yml
sudo sed -i 's#slow.log#'"$3"'#g' /usr/local/filebeat/config/$2.yml
sudo sed -i 's#error.log#'"$4"'#g' /usr/local/filebeat/config/$2.yml
sudo sed -i 's#ip:port#'"$5"'#g' /usr/local/filebeat/config/$2.yml

sudo ps aux|grep $2.yml|grep -v grep|awk '{print $2}'|xargs sudo kill -9 >/dev/null 2>&1

sudo nohup /usr/local/filebeat/filebeat -e -c /usr/local/filebeat/config/$2.yml >/dev/null 2>&1 &

sudo sed -i '/'"$2"'.yml &$/d' /etc/rc.local
sudo echo "nohup /usr/local/filebeat/filebeat -e -c /usr/local/filebeat/config/$2.yml &" >> /etc/rc.d/rc.local
sudo chmod +x /etc/rc.d/rc.local

cp -f test_mysqllog.sh mysql_$2.sh
sudo sed -i 's#slow.log#'"$3"'#g' mysql_$2.sh
sudo sed -i 's#error.log#'"$4"'#g' mysql_$2.sh

sleep 3

/bin/bash /tmp/mysql_$2.sh



