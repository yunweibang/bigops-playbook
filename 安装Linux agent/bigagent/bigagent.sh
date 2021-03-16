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

echo "${CURL} ${proxy}/agent/version -d \"id=${host_id}&ak=${host_ak}&agent_version=4.0.5.3\""
echo
${CURL} ${proxy}/agent/version -d "id=${host_id}&ak=${host_ak}&agent_version=4.0.5.3"
echo -e "\n\n"

if [ $? != 0 ];then
    echo "# 任务失败"
fi

if [ "$((${CUR_SEC} % 10))" == '0' ];then
    PCPU="$(/usr/bin/ps -eo user,pid,pcpu,pmem,tty,stat,lstart,etime,cmd --sort=-pcpu|sed '1d'|head -n 5)"
    RSS="$(/usr/bin/ps -eo user,pid,pcpu,pmem,tty,stat,lstart,etime,cmd --sort=-rss|sed '1d'|head -n 5)"
    PS="$(echo -e "${PCPU}\n${RSS}"|sort -n|uniq|grep -Ev '0.0  0.0')"
    CPU_CORES="$(cat /proc/cpuinfo |grep ^processor|wc -l)"
    PS_SNAPSHOT="$(echo "${PS}"|grep -Ev rngd|awk '{if(($3/'"${CPU_CORES}"'>90)||($4>90))print}')"

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

if [[ "$(date +%M)" == '10' ]] || [[ "$(date +%M)" == '40' ]] ;then 
    NETSTAT_IP=$(sudo netstat -npltu|sed '1,2d'|grep -Ev '^(tcp6|udp6)'|awk '/udp/{$5=$5"||LISTEN"}{print $1"||"$2"||"$3"||"$4"||"$5"||"$6"||"$7,$8,$9,$10}'|awk -F/ '{print $1"||"$2}'|grep -Ev 'ntpdate'|sed 's/[ ]*$/||/g'|sed 's/||||$/||/g')
    echo "${CURL} ${proxy}/agent/netstat -d \"id=${host_id}&ak=${host_ak}&type=ip\" --data-urlencode \"netstat=${NETSTAT_IP}\""

    if [ ! -z "${NETSTAT_IP}" ];then
        ${CURL} ${proxy}/agent/netstat -d "id=${host_id}&ak=${host_ak}&type=ip" --data-urlencode "netstat=${NETSTAT_IP}"
        echo
    fi

    echo -e "\n\n"

    NETSTAT_IPC=$(sudo netstat -nplx|sed '1,2d'|grep -Ev '^(tcp6|udp6)'|awk 'sub("[/]"," ",$9)'|grep -Ev 'shim.sock'|awk '{print $1"||"$2"||"$3"||"$4"||"$5"||"$6"||"$7"||"$8"||"$9"||"$10"||"$11,$12,$13}'|sed 's/[ ]*$/||/g'|sed 's/||||$/||/g')
    echo "${CURL} ${proxy}/agent/netstat -d \"id=${host_id}&ak=${host_ak}&type=ipc\" --data-urlencode \"netstat=${NETSTAT_IPC}\""

    if [ ! -z "${NETSTAT_IPC}" ];then
        ${CURL} ${proxy}/agent/netstat -d "id=${host_id}&ak=${host_ak}&type=ipc" --data-urlencode "netstat=${NETSTAT_IPC}"
        echo
    fi
fi

echo -e "\n\n"

APP="$(${CURL} -s ${proxy}/agent/app/lld  -d "id=${host_id}&ak=${host_ak}")"

if [[ "$((${CUR_SEC} % 10))" == '0' ]] && [[ ! -z "${APP}" ]];then
    NETSTAT=$(sudo netstat -nplt|sed '1,2d'|grep -Ev '^(tcp6|udp)'|awk '{print $4,$NF}'|awk -F'[ |:|/]' '{print $2,$(NF-1)}'|sort -k 2 -u)
    echo "${NETSTAT}"|while read i
    do
        PORT=$(echo "${i}"|awk '{print $1}')
        PID=$(echo "${i}"|awk '{print $2}')
        echo "${APP}"|while read app
        do
            echo "${app}"
            NAME="$(echo "${app}"|awk -F'[|][|]' '{print $1}')"
            KEYWORD="$(echo "${app}"|awk -F'[|][|]' '{print $2}')"
            echo "${KEYWORD}"
            if [[ -f /proc/${PID}/cmdline ]] && [[ ! -z "${KEYWORD}" ]];then
                if [ ! -z "$(echo "${KEYWORD}"|grep -E '(mysql|mysqld)')" ];then
                    if [ ! -z "$(cat /proc/${PID}/cmdline|grep -Ei "${KEYWORD}"|grep -Ev '(^Binary|percona|mariadb)')" ];then
                        echo "${CURL} ${proxy}/agent/exportergateway -d \"id=${host_id}&ak=${host_ak}&app_name=${NAME}&app_port=${PORT}\""
                        ${CURL} ${proxy}/agent/exportergateway -d "id=${host_id}&ak=${host_ak}&app_name=${NAME}&app_port=${PORT}"
                        echo
                    fi
                else
                    if [ ! -z "$(cat /proc/${PID}/cmdline|grep -Ei "${KEYWORD}")" ];then
                        echo "${CURL} ${proxy}/agent/exportergateway -d \"id=${host_id}&ak=${host_ak}&app_name=${NAME}&app_port=${PORT}\""
                        ${CURL} ${proxy}/agent/exportergateway -d "id=${host_id}&ak=${host_ak}&app_name=${NAME}&app_port=${PORT}"
                        echo
                    fi
                fi
            fi
        done
    done
fi

# echo -e "\n\n"

# if [ "$(date +%H%M)" == '0315' ];then
#     CROND_STATUS="$(ps aux|grep -v grep|grep -E '(cron|crond)($| )')"
#     if [ ! -z "${CROND_STATUS}" ];then
#       CROND_STATUS=on
#     else
#       CROND_STATUS=off
#     fi

#     CRONTAB="$(sudo cat /var/spool/cron/root)"
#     echo "${CURL} ${proxy}/agent/cron -d \"id=${host_id}&ak=${host_ak}&crond_status=${CROND_STATUS}\" --data-urlencode \"cron=${CRONTAB}\""

#     if [ ! -z "${CRONTAB}" ];then
#         ${CURL} ${proxy}/agent/cron -d "id=${host_id}&ak=${host_ak}&crond_status=${CROND_STATUS}" --data-urlencode "cron=${CRONTAB}"
#         echo
#     fi
# fi

echo -e "\n\n"

if [[ "$(date +%H%M)" == '2315' ]] || [[ "$(date +%H%M)" == '1215' ]];then
    echo
    timeout 15 /bin/bash ${base_dir}/hostinfo.sh
fi


