#!/bin/sh

export PATH=/opt/bigops/bigagent/bin:/opt/exporter:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin:/usr/local/sbin

alias cp=cp
alias mv=mv
alias rm=rm

rm -f /opt/exporter/key/syskey.prom2
rm -f /opt/exporter/key/syskey.prom.tmp
echo >/opt/exporter/key/syskey.tmp

/usr/bin/df -k|awk '/\/dev\/mapper/{print $1}' >/opt/exporter/key/mapper.txt

if [[ -f /usr/sbin/lvdisplay ]] && [[ ! -z "$(cat /opt/exporter/key/mapper.txt)" ]]; then
  cat /opt/exporter/key/mapper.txt|while read i
  do
    DM="$(sudo /usr/sbin/lvdisplay "$i"|grep 'Block device'|awk -F: '{print "dm-"$NF}')"
    sudo grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_readbytes{device=\""dev"\"}",$6*512}' >>/opt/exporter/key/syskey.tmp
    sudo grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_writebytes{device=\""dev"\"}",$10*512}' >>/opt/exporter/key/syskey.tmp
    sudo grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_readiops{device=\""dev"\"}",$4}' >>/opt/exporter/key/syskey.tmp
    sudo grep "$DM" /proc/diskstats|awk -v dev="$i" '{if($3 ~ /[0-9]$/) print "disk_writeiops{device=\""dev"\"}",$8}' >>/opt/exporter/key/syskey.tmp
  done
fi

sudo /usr/bin/df -k|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk '{print "disk_fs_usage{device=\""$1"\"}",$5}'|sed 's/%//'|awk '{if($2 ~/^[0-9]/) print}' >>/opt/exporter/key/syskey.tmp
sudo /usr/bin/df -i|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|awk '{print "disk_inode_usage{device=\""$1"\"}",$5}'|sed 's/%//'|awk '{if($2 ~/^[0-9]/) print}' >>/opt/exporter/key/syskey.tmp

sudo grep -Ev '(dm-|sr|fb)' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_readbytes{device=\"/dev/"$3"\"}",$6*512}' >>/opt/exporter/key/syskey.tmp
sudo grep -Ev '(dm-|sr|fb)' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_writebytes{device=\"/dev/"$3"\"}",$10*512}' >>/opt/exporter/key/syskey.tmp
sudo grep -Ev '(dm-|sr|fb)' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_readiops{device=\"/dev/"$3"\"}",$4}' >>/opt/exporter/key/syskey.tmp
sudo grep -Ev '(dm-|sr|fb)' /proc/diskstats|awk '{if($3 ~ /[0-9]$/) print "disk_writeiops{device=\"/dev/"$3"\"}",$8}' >>/opt/exporter/key/syskey.tmp

disk_fs_max_usage="$(sudo df -k|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|grep '%'|awk '{print $5}'|sed 's/%//g'|sort -r|head -n 1)"
disk_inode_max_usage="$(sudo df -i|grep ^/dev/|grep -Ev '^/dev/(sr|fb)'|grep '%'|awk '{print $5}'|sed 's/%//g'|sort -r|head -n 1)"
echo "disk_fs_max_usage ${disk_fs_max_usage}" >>/opt/exporter/key/syskey.tmp
echo "disk_inode_max_usage ${disk_inode_max_usage}" >>/opt/exporter/key/syskey.tmp

PS_PROC="$(sudo ps -A -ostat,ppid,pid,cmd)"
proc_total="$(echo "${PS_PROC}"|wc -l)"
proc_running="$(echo "${PS_PROC}"|grep -E '^[R]'|wc -l)"
proc_sleeping="$(echo "${PS_PROC}"|grep -E '^[S]'|wc -l)"
proc_zombie="$(echo "${PS_PROC}"|grep -E '^[Zz]'|wc -l)"

echo "proc_total ${proc_total}" >>/opt/exporter/key/syskey.tmp
echo "proc_running ${proc_running}" >>/opt/exporter/key/syskey.tmp
echo "proc_sleeping ${proc_sleeping}" >>/opt/exporter/key/syskey.tmp
echo "proc_zombie ${proc_zombie}" >>/opt/exporter/key/syskey.tmp

echo >>/opt/exporter/key/syskey.tmp

PROCS=$(sudo ps -eo "%c"|awk -F/ '{print $1}'|grep -Ev '(grep|COMMAND|scsi|xfs)'|sort|uniq)

if [ ! -z "${PROCS}" ];then
  echo "${PROCS}"|awk '{print "proc_status{name=\""$1"\"} 1"}' >>/opt/exporter/key/syskey.tmp
fi

if [ ! -z "$(lsb_release -a|grep -i ^Release|awk '{print $2}'|grep ^6)" ];then 
  ss_c6 -s|awk '/estab/{print $2,$4,$10,$12}'|sed 's/[,/()]/ /g'|awk '{print "tcp_total "$1"\ntcp_estab "$2"\ntcp_synrecv "$3"\ntcp_timewait "$4}' >>/opt/exporter/key/syskey.tmp
else
  ss -s|awk '/estab/{print $2,$4,$10,$12}'|sed 's/[,/()]/ /g'|awk '{print "tcp_total "$1"\ntcp_estab "$2"\ntcp_synrecv "$3"\ntcp_timewait "$4}' >>/opt/exporter/key/syskey.tmp
fi

cpu_usage="$(sudo /opt/exporter/mpstat -P ALL 1 10|awk '$1 ~ /^Average/ && $2 ~ /all/ {print 100-$NF}'|head -n 1)"
echo "cpu_usage ${cpu_usage}" >>/opt/exporter/key/syskey.tmp

awk '{if($1 ~ /^[a-zA-Z]/ && $2 ~ /^[0-9]/ && $3 == "") print}' /opt/exporter/key/syskey.tmp|sort -uk1,1 >/opt/exporter/key/syskey.tmp2

if [ ! -z "$(cat /opt/exporter/key/syskey.tmp2|grep ^cpu_usage)" ];then
  cp -f /opt/exporter/key/syskey.tmp2 /opt/exporter/key/syskey.prom
fi

