#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

alias cp=cp
alias mv=mv

cd /tmp/

if [ ! -f slow.log ];then
  echo "slow.log不存在，退出！"
  exit
fi

cat << EOF >> slow.log
# Time: $(date +%Y-%m-%dT%H:%M:%S.000000)+08:00
# User@Host: root[root] @  [192.168.50.2]  Id:   141
# Query_time: 1.143302  Lock_time: 0.000091 Rows_sent: 0  Rows_examined: 1
SET timestamp=$(date +%s);
test mysql slowlog sql;
EOF

if [ ! -f error.log ];then
  echo "error.log不存在，退出！"
  exit
fi

echo $(date +%Y-%m-%dT%H:%M:%S.000000)+08:00 0 [Warning] test mysql errorlog >>error.log

