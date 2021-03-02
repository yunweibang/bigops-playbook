#!/bin/sh

export PATH=/opt/bigops/bigagent/bin:/opt/exporter:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin:/usr/local/sbin

alias cp=cp
alias rm=rm

echo >/opt/exporter/key/syskey.tmp

disk_fs_max_usage="$(sudo df -k|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|grep '%'|awk '{print $5}'|sed 's/%//g'|sort -r|head -n 1)"
disk_inode_max_usage="$(sudo df -i|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|grep '%'|awk '{print $5}'|sed 's/%//g'|sort -r|head -n 1)"

echo "disk_fs_max_usage ${disk_fs_max_usage}" >>/opt/exporter/key/syskey.tmp
echo "disk_inode_max_usage ${disk_inode_max_usage}" >>/opt/exporter/key/syskey.tmp

echo >>/opt/exporter/key/syskey.tmp

PROCS=$(sudo ps -eo "%c"|awk -F/ '{print $1}'|grep -Ev '(grep|COMMAND|scsi|xfs)'|sort|uniq)

if [ ! -z "${PROCS}" ];then
  echo "${PROCS}"|awk '{print "proc_status{name=\""$1"\"} 1"}' >>/opt/exporter/key/syskey.tmp
fi

if [ -f /bin/mpstat ];then
    cpu_usage="$(sudo /bin/mpstat -P ALL 1 10|awk '$1 ~ /^Average/ && $2 ~ /all/ {print 100-$NF}'|head -n 1)"
elif [ /opt/exporter/mpstat ]; then
	cpu_usage="$(sudo /opt/exporter/mpstat -P ALL 1 5|awk '$1 ~ /^Average/ && $2 ~ /all/ {print 100-$NF}'|head -n 1)"
fi

echo "cpu_usage ${cpu_usage}" >>/opt/exporter/key/syskey.tmp

awk '{if($1 ~ /^[a-zA-Z]/ && $2 ~ /^[0-9]/ && $3 == "") print}' /opt/exporter/key/syskey.tmp|sort -uk1,1 >/opt/exporter/key/syskey.tmp2

if [ ! -z "$(grep ^cpu_usage /opt/exporter/key/syskey.tmp2|awk '{print $2}'|grep ^[0-9])" ];then
  cp -f /opt/exporter/key/syskey.tmp2 /opt/exporter/key/syskey.prom
fi
