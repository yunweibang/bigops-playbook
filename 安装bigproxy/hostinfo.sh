#!/bin/bash

eval $(grep -Ev '^spring_' /opt/bigops/bigproxy/config/bigproxy.properties|grep -Ev '^#')

export PROXY="http://127.0.0.1:60001"
export BASE_DIR="/opt/bigops/bigproxy"
export TEMP_DIR="${BASE_DIR}/hostinfo_temp"

export HOST_ID=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $1}')
export HOST_AK=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $2}')
export CLIENT_IP=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $3}')
export SYSTEM_CAT=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $4}')
export EXEC_TIME=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $5}')
export CUR_SEC=$(date -d @${EXEC_TIME} "+%M"|sed -r 's/0*([0-9])/\1/')

export CURL="timeout 10 curl -s -X POST"

export ANSIBLE_HOSTS="${TEMP_DIR}/${HOST_ID}_host"
export ANSIBLE_CMD="timeout 10 ansible -i ${ANSIBLE_HOSTS} all"


find ${TEMP_DIR} -mtime +1 -name "*" -exec rm -f {} \;

if [[ -z "${HOST_ID}" ]] || [[ -z "${HOST_AK}" ]] || [[ -z "${CLIENT_IP}" ]] || [[ -z "${SYSTEM_CAT}" ]] || [[ -z "${EXEC_TIME}" ]];then
    echo "HOST_ID、HOST_AK、CLIENT_IP、SYSTEM_CAT、EXEC_TIME有一项为空"
    exit
fi

if [ ! -s "${ANSIBLE_HOSTS}" ];then
    echo "not found ansible hosts:${ANSIBLE_HOSTS}"
    exit
fi

if [ ! -d "${TEMP_DIR}" ];then
    mkdir -p "${TEMP_DIR}"
fi

if [ "${SYSTEM_CAT}" == 'Windows' ];then
   timeout 15 /bin/bash ${BASE_DIR}/hostinfo_windows.sh
fi