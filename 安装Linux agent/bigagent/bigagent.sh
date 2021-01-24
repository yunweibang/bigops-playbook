#!/bin/bash

alias mv=mv
alias cp=cp

setenforce 0 >/dev/null 2>&1

export PATH=/opt/bigops/bigagent/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/root/bin

source /opt/bigops/bigagent/bigagent.conf

chmod 777 /opt/bigops/bigagent/bin/ -R

base_dir=/opt/bigops/bigagent/

export CURL="timeout 10 curl -X POST"
export CUR_SEC=$(date +%M|sed -r 's/0*([0-9])/\1/')


if [ -f bigagent.pid ];then
    timeout 5 sudo kill -9 $(cat bigagent.pid) 2>/dev/null
    echo $$ >bigagent.pid
fi

if [[ ! -z "$(echo "${proxy_ip}"|grep "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")" ]] && [[ ! -z "${proxy_port}" ]];then
    export proxy=http://${proxy_ip}:${proxy_port}
else
    echo "http://${proxy_ip}:${proxy_port}错误，退出!"
    exit
fi

echo

echo "${CURL} ${proxy}/agent/version -d \"id=${host_id}&ak=${host_ak}&agent_version=4.0.4.4\""
echo
${CURL} ${proxy}/agent/version -d "id=${host_id}&ak=${host_ak}&agent_version=4.0.4.4"
echo -e "\n\n"

if [ $? != 0 ];then
    echo "# 任务失败"
fi

if [ "$((${CUR_SEC} % 15))" = '0' ];then
    
    PCPU=$(/usr/bin/ps -eo user,pid,pcpu,pmem,tty,stat,lstart,etime,cmd --sort=-pcpu|sed '1d'|head -n 5)
    RSS=$(/usr/bin/ps -eo user,pid,pcpu,pmem,tty,stat,lstart,etime,cmd --sort=-rss|sed '1d'|head -n 5)
    PS=$(echo -e "${PCPU}\n${RSS}"|sort -n|uniq|grep -Ev '0.0  0.0')
    PS_SNAPSHOT=$(echo "${PS}"|awk '{if(($3>90)||($4>90))print}')

    echo "${CURL} ${proxy}/agent/ps -d \"id=${host_id}&ak=${host_ak}\" --data-urlencode \"ps=${PS}\""

    if [ ! -z "${PS}" ];then
        ${CURL} ${proxy}/agent/ps -d "id=${host_id}&ak=${host_ak}" --data-urlencode "ps=${PS}"
        echo
    fi

    if [ ! -z "${PS_SNAPSHOT}" ];then
        ${CURL} ${proxy}/agent/ps_snapshot -d "id=${host_id}&ak=${host_ak}" --data-urlencode "ps_snapshot=${PS_SNAPSHOT}"
        echo
    fi

fi

echo -e "\n\n"

if [ "$((${CUR_SEC} % 20))" = '0' ];then
   
    NETSTAT_IP=$(timeout 5 sudo netstat -npltu|sed '1,2d'|grep -Ev '^(tcp6|udp6)'|awk '/udp/{$5=$5"||LISTEN"}{print $1"||"$2"||"$3"||"$4"||"$5"||"$6"||"$7,$8,$9,$10}'|awk -F/ '{print $1"||"$2}'|grep -Ev 'ntpdate'|sed 's/[ ]*$/||/g'|sed 's/||||$/||/g')
    echo "${CURL} ${proxy}/agent/netstat -d \"id=${host_id}&ak=${host_ak}&type=ip\" --data-urlencode \"netstat=${NETSTAT_IP}\""

    if [ ! -z "${NETSTAT_IP}" ];then
        ${CURL} ${proxy}/agent/netstat -d "id=${host_id}&ak=${host_ak}&type=ip" --data-urlencode "netstat=${NETSTAT_IP}"
        echo
    fi

    echo -e "\n\n"

    NETSTAT_IPC=$(timeout 5 sudo netstat -nplx|sed '1,2d'|grep -Ev '^(tcp6|udp6)'|awk 'sub("[/]"," ",$9)'|grep -Ev 'shim.sock'|awk '{print $1"||"$2"||"$3"||"$4"||"$5"||"$6"||"$7"||"$8"||"$9"||"$10"||"$11,$12,$13}'|sed 's/[ ]*$/||/g'|sed 's/||||$/||/g')
    echo "${CURL} ${proxy}/agent/netstat -d \"id=${host_id}&ak=${host_ak}&type=ipc\" --data-urlencode \"netstat=${NETSTAT_IPC}\""

    if [ ! -z "${NETSTAT_IPC}" ];then
        ${CURL} ${proxy}/agent/netstat -d "id=${host_id}&ak=${host_ak}&type=ipc" --data-urlencode "netstat=${NETSTAT_IPC}"
        echo
    fi

fi

echo -e "\n\n"

if [ "$(date +%M)" == '10' ];then
   
    CROND_STATUS=$(ps aux|grep -v grep|grep -E '(cron|crond)($| )')
    if [ ! -z "${CROND_STATUS}" ];then
       CROND_STATUS=on
    else
       CROND_STATUS=off
    fi

    CRONTAB=$(timeout 5 sudo cat /var/spool/cron/root)
    echo "${CURL} ${proxy}/agent/cron -d \"id=${host_id}&ak=${host_ak}&crond_status=${CROND_STATUS}\" --data-urlencode \"cron=${CRONTAB}\""

    if [ ! -z "${CRONTAB}" ];then
        ${CURL} ${proxy}/agent/cron -d "id=${host_id}&ak=${host_ak}&crond_status=${CROND_STATUS}" --data-urlencode "cron=${CRONTAB}"
        echo
    fi

fi

echo -e "\n\n"

if [ "$(date +%M)" == '20' ];then
    
    CMD=$(ps aux|grep -E 'zabbix_agentd[ ]'|awk '{print $11}'|head -n 1)

    if [ ! -z "${CMD}" ];then
        VER=$(${CMD} -V|head -n 1|awk '{print $NF}')
    else
        echo "zabbix_agentd not running"
        VER="not_running"
    fi

    echo "${CURL} ${proxy}/agent/zabbixagent/version -d \"id=${host_id}&ak=${host_ak}&zbx_agent_version=${VER}\""
    ${CURL} ${proxy}/agent/zabbixagent/version -d "id=${host_id}&ak=${host_ak}&zbx_agent_version=${VER}" 

fi

echo -e "\n\n"

if [ "$(date +%M)" == '30' ];then
    echo
    timeout 10 /bin/bash ${base_dir}/hostinfo.sh
fi

#软件版本
# RUN_TIME=$(date +%H%M%S)
# if [ "${RUN_TIME}" = '060000' ];then
#     echo
#     timeout 10 /bin/bash ${base_dir}/soft_version.sh
# fi

