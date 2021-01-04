#!/bin/bash

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin
export CURL="curl -s --connect-timeout 3 -m 10 -X POST"

memtotal=$(free -m | grep Mem | awk '{print $2}')
memavailable=$(free -m | grep Mem | awk '{print $7}')
echo ${memavailable} ${memtotal} | awk '{print "mem_usage "100 - ($1/$2 * 100.0)}' >/opt/exporter/key/syskey.prom.tmp

TCP_PORT=$(ss -nplt|awk '{print $4}'|awk -F: '{print $NF}'|grep -E '^[0-9]')
UDP_PORT=$(ss -nplu|awk '{print $4}'|awk -F: '{print $NF}'|grep -E '^[0-9]')

if [ ! -z "${TCP_PORT}" ];then
    echo "${TCP_PORT}"|awk '{print "tcp_port_status_{port=\""$1"\"} 1" }' >>/opt/exporter/key/syskey.prom.tmp
fi

if [ ! -z "${UDP_PORT}" ];then
    echo "${UDP_PORT}"|awk '{print "udp_port_status_{port=\""$1"\"} 1" }' >>/opt/exporter/key/syskey.prom.tmp
fi

PROCS=$(ps -eo "%c"|awk -F/ '{print $1}'|grep -Ev '(grep|COMMAND)' |sort|uniq)

if [ ! -z "${PROCS}" ];then
    echo "${PROCS}"|awk '{print "proc_status{name=\""$1"\"} 1" }' >>/opt/exporter/key/syskey.prom.tmp
fi

df -k|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk '{print "disk_fs_usage{device=\""$1"\"}",$5}'|sed 's/%//'|awk '{if($2 ~/^[0-9]/) print}' >>/opt/exporter/key/syskey.prom.tmp
df -i|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk '{print "disk_inode_usage{device=\""$1"\"}",$5}'|sed 's/%//'|awk '{if($2 ~/^[0-9]/) print}' >>/opt/exporter/key/syskey.prom.tmp

grep -v 'dm-' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_readbytes{device=\"/dev/"$3"\"}",$6*512}' >>/opt/exporter/key/syskey.prom.tmp
grep -v 'dm-' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_writebytes{device=\"/dev/"$3"\"}",$10*512}' >>/opt/exporter/key/syskey.prom.tmp
grep -v 'dm-' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_readiops{device=\"/dev/"$3"\"}",$4}' >>/opt/exporter/key/syskey.prom.tmp
grep -v 'dm-' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_writeiops{device=\"/dev/"$3"\"}",$8}' >>/opt/exporter/key/syskey.prom.tmp

df -k|grep mapper|awk '{print $1}'|while read i
do
	if [ ! -z "$(echo "$i")" ];then
	    DM=$(lvdisplay "$i"|grep 'Block device'|awk -F: '{print "dm-"$NF}')
	    grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_readbytes{device=\""dev"\"}",$6*512}' >>/opt/exporter/key/syskey.prom.tmp
		grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_writebytes{device=\""dev"\"}",$10*512}' >>/opt/exporter/key/syskey.prom.tmp 
		grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_readiops{device=\""dev"\"}",$4}' >>/opt/exporter/key/syskey.prom.tmp 
		grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_writeiops{device=\""dev"\"}",$8}' >>/opt/exporter/key/syskey.prom.tmp
	fi
done


logical_cpu_total=$(cat /proc/cpuinfo| grep "processor"|wc -l)
logined_users_total=$(who |wc -l)
echo "logical_cpu_total ${logical_cpu_total}" >>/opt/exporter/key/syskey.prom.tmp
echo "logined_users_total ${logined_users_total}" >>/opt/exporter/key/syskey.prom.tmp

#disk_used=$(df -m|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk 'BEGIN{sum=0}{if($3!~/anon/)sum+=$3}END{print sum}')
#disk_total=$(df -m|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk 'BEGIN{sum=0}{if($2!~/anon/)sum+=$2}END{print sum}')
#echo "${disk_used}" "${disk_total}"|awk '{print "disk_total_usage",$1/$2*100}' >>/opt/exporter/key/syskey.prom.tmp

disk_fs_max_usage=$(df -k|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk '{print $5}'|sed 's/%//g'|sort -r|head -n 1)
disk_inode_max_usage=$(df -i|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk '{print $5}'|sed 's/%//g'|sort -r|head -n 1)
echo "disk_fs_max_usage ${disk_fs_max_usage}" >>/opt/exporter/key/syskey.prom.tmp
echo "disk_inode_max_usage ${disk_inode_max_usage}" >>/opt/exporter/key/syskey.prom.tmp

if [ ! -z "$(lsb_release -a|grep -i ^Release|awk '{print $2}'|grep ^6)" ];then 
    ss_c6 -s|awk '/estab/{print $2,$4,$10,$12}'|sed 's/[,/()]/ /g'|awk '{print "tcp_total "$1"\ntcp_estab "$2"\ntcp_synrecv "$3"\ntcp_timewait "$4}' >>/opt/exporter/key/syskey.prom.tmp
else
	ss -s|awk '/estab/{print $2,$4,$10,$12}'|sed 's/[,/()]/ /g'|awk '{print "tcp_total "$1"\ntcp_estab "$2"\ntcp_synrecv "$3"\ntcp_timewait "$4}' >>/opt/exporter/key/syskey.prom.tmp
fi

top -bn 1|grep -i tasks|awk '{print "proc_total "$2"\nproc_running "$4"\nproc_sleeping "$6"\nproc_zombie "$(NF-1)}' >>/opt/exporter/key/syskey.prom.tmp

cpu_usage=$(mpstat -P ALL 1 15|awk '$1 ~ /:$/ && $2 ~ /all/ {print 100-$NF}')
echo "cpu_usage ${cpu_usage}" >>/opt/exporter/key/syskey.prom.tmp

megaraid_predictive_failure=$(MegaCli -PDList -aALL -NoLog |grep -E '^Predictive Failure'|awk '{print $NF}'|sort -r|head -n 1)
echo "megaraid_predictive_failure ${megaraid_predictive_failure}" >>/opt/exporter/key/syskey.prom.tmp

awk '{if($2 ~ /^[0-9]/ && $3 == "") print}' /opt/exporter/key/syskey.prom.tmp|sort|uniq >/opt/exporter/key/syskey.prom


