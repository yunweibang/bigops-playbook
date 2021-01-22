#!/bin/bash

source /opt/bigops/bigagent/bigagent.conf

# NETSTAT=$(netstat -npl)

# if [ ! -z "$(echo "${NETSTAT}"|grep '/sshd')" ];then
# 	name=sshd
# 	PID=$(echo "${NETSTAT}"|grep '/sshd'|awk -F/ '{print $1}'|awk '{print $NF}'|head -n 1)
# 	path=$(ls -l /proc/${PID}/exe|awk '{print $NF}')
# 	version=$(${path} -v 2>&1|grep OpenSSH_|awk -F, '{print $1}'|awk -F_ '{print $2}')
# 	${CURL} ${proxy}/api/agent/soft/version -d "id=${host_id}&ak=${host_ak}&name=${name}&path=${path}&version=${version}"
# 	echo
# fi


# if [ ! -z "$(echo "${NETSTAT}"|grep '/nginx')" ];then
# 	name=nginx
# 	PID=$(echo "${NETSTAT}"|grep '/nginx'|awk -F/ '{print $1}'|awk '{print $NF}'|head -n 1)
# 	path=$(ls -l /proc/${PID}/exe|awk '{print $NF}')
# 	version=$(${path} -v 2>&1|awk -F/ '{print $NF}')
# 	${CURL} ${proxy}/api/agent/soft/version -d "id=${host_id}&ak=${host_ak}&name=${name}&path=${path}&version=${version}"
# 	echo
# fi

# if [ ! -z "$(echo "${NETSTAT}"|grep '/zabbix_agentd')" ];then
# 	name=zabbix_agentd
# 	PID=$(echo "${NETSTAT}"|grep '/zabbix_agentd'|awk -F/ '{print $1}'|awk '{print $NF}'|head -n 1)
# 	path=$(ls -l /proc/${PID}/exe|awk '{print $NF}')
# 	version=$(${path} -V 2>&1|head -n 1|awk '{print $NF}')
# 	${CURL} ${proxy}/api/agent/soft/version -d "id=${host_id}&ak=${host_ak}&name=${name}&path=${path}&version=${version}"
# 	echo
# fi

# if [ ! -z "$(echo "${NETSTAT}"|grep '/mysqld')" ];then
# 	name=mysqld
# 	PID=$(echo "${NETSTAT}"|grep '/mysqld'|awk -F/ '{print $1}'|awk '{print $NF}'|head -n 1)
# 	path=$(ls -l /proc/${PID}/exe|awk '{print $NF}')
# 	version=$(${path} -V 2>&1|head -n 1|awk '{print $3}')
# 	${CURL} ${proxy}/api/agent/soft/version -d "id=${host_id}&ak=${host_ak}&name=${name}&path=${path}&version=${version}"
# 	echo
# fi

# if [ "$(uptime|awk '{print $(NF-2)}'|awk -F'.' '{if($1<2) print "ok"}')" = 'ok' ];then
# 	RPM=$(rpm -aq)
# 	echo "${RPM}"|while read rpm_list
# 	do
# 	    name=$(echo "${rpm_list}"|awk -F'-[0-9]' '{print $1}')
# 	    path=
# 	    version=$(echo "${rpm_list}"|sed ':a;s/^[^0-9][^-]*-//;ta;s/.e.*//')
# 	    ${CURL} ${proxy}/agent/soft/version -d "id=${host_id}&ak=${host_ak}&name=${name}&path=${path}&version=${version}"
# 	     echo
# 	done
# fi