#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

alias cp=cp
alias mv=mv

if [ `arch` != "x86_64" ];then
    echo "不支持当前架构，只支持x86_64"
    exit
fi

if [ -f /opt/bigops/bigagent/bigagent.conf ];then
    cp -f /opt/bigops/bigagent/bigagent.conf /opt/bigops/bigagent.conf
fi

cd /opt/bigops/
rm -rf /opt/bigops/bigagent
tar zxvf bigagent.tar.gz

if [ -f /opt/bigops/bigagent.conf ];then
	mv -f /opt/bigops/bigagent.conf /opt/bigops/bigagent/bigagent.conf 
fi

sudo chown -R bigops:bigops /opt/bigops/

