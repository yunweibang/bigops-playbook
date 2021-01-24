#!/bin/bash

eval $(grep -Ev '^spring_' /opt/bigops/bigproxy/config/bigproxy.properties|grep -Ev '^#')

export PROXY="http://127.0.0.1:60001"
export BASE_DIR="/opt/bigops/bigproxy"
export TEMP_DIR="${BASE_DIR}/hostmon_temp"

export HOST_ID=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $1}')
export HOST_AK=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $2}')
export CLIENT_IP=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $3}')
export SYSTEM_CAT=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $4}')
export EXEC_TIME=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $5}')
export CUR_SEC=$(date -d @${EXEC_TIME} "+%M"|sed -r 's/0*([0-9])/\1/')

export LLD_ALL_METRICS="${TEMP_DIR}/${HOST_ID}_lld_all_metrics"
export ALL_METRICS="${TEMP_DIR}/${HOST_ID}_all_metrics"
export CURL="timeout 120 curl -s -X POST"
export SEND="${CURL}"" ${PROXY}/agent/mon/host"
export LLD_SEND="${CURL}"" ${PROXY}/agent/discovery/host"
export LLD_UPDATE="${CURL}"" ${PROXY}/agent/discovery/updatenetif"

find ${TEMP_DIR} -mtime +1 -name "*" -exec rm -f {} \;

if [[ -z "${HOST_ID}" ]] || [[ -z "${HOST_AK}" ]] || [[ -z "${CLIENT_IP}" ]] || [[ -z "${EXEC_TIME}" ]];then
    echo "HOST_ID、HOST_AK、CLIENT_IP、EXEC_TIME有一项为空"
    exit
fi

if [ ! -d "${TEMP_DIR}" ];then
    mkdir -p "${TEMP_DIR}"
fi

date
echo -e "proxy_id：${proxy_id}"
echo -e "proxy_name：${proxy_name}"

echo "/bin/bash /opt/bigops/bigproxy/hostmon.sh" \'"$1"\'

echo "EXEC_TIME：$(date -d @${EXEC_TIME} "+%Y-%m-%d %H:%M:%S")"


echo -e "\n--------获取监控项列表--------"

#echo "获取item"
echo "${CURL} ${PROXY}/agent/template/host -d \"id=${HOST_ID}&ak=${HOST_AK}\""

ITEM="$(${CURL} ${PROXY}/agent/template/host -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"

if [ $? -ne 0 ];then
  echo "curl超时"
  sleep 2
  ITEM="$(${CURL} ${PROXY}/agent/template/host -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"
  if [ $? -ne 0 ];then
    echo "curl超时"
    sleep 2
    ITEM="$(${CURL} ${PROXY}/agent/template/host -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"
  fi
fi


echo -e "\n第一列更新方式、第二列KEY、第三列间隔、第四列自动发现、第五列模板ID、第六列端点"
#例子：1||mem_usage,cpu_usage||1||none||11||http://172.31.173.25:9100/metrics
#echo -e "更新方式：0简单Ping、1Exporter、2Ansible、3SNMP、4IPMI、9自定义。"

ITEM="$(echo "${ITEM}"|sed '/^[ \t]*$/d')"

TIME=$(date -d @${EXEC_TIME} "+%Y-%m-%d %H:%M:%S")


echo -e "\n--------获取ITEM列表--------"

if [ ! -z "$(echo "${ITEM}"|grep -E '^[0-9]\|\|')" ];then
  echo "${ITEM}" >${TEMP_DIR}/${HOST_ID}_item_list
else
  echo "错误监控项：hostid=${HOST_ID},exec_time=${EXEC_TIME},time=${TIME},msg=${ITEM}"
  echo "读取缓存监控项配置"
  ITEM="$(cat ${TEMP_DIR}/${HOST_ID}_item_list)"
fi

echo "${ITEM}"
echo 

#处理简单Ping的icmpping监控项
if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|icmpping_status\|\|')" ];then

  INTERVAL="$(echo "${ITEM}"|grep -E '^0\|\|icmpping_status\|\|'|head -n 1|awk -F'[|][|]' '{print $3}')"
  if [[ "$((${CUR_SEC} % ${INTERVAL}))" -eq 0 ]];then
    ICMPPING="$(timeout 120 fping -q -c 2 "${CLIENT_IP}" 2>&1)"
    ICMPPING_LOSS="$(echo "${ICMPPING}"|awk '/loss/{print $5}'|awk -F/ '{print $NF}'|sed 's/%//g'|sed 's/,//g')"
    ICMPPING_LATENCY="$(echo "${ICMPPING}"|awk '/xmt/{print $NF}'|awk -F/ '{print $2}')"
    echo -e "\n--------处理Ping监控项--------"
    if [[ ! -z "${ICMPPING_LOSS}" ]] && [[ "${ICMPPING_LOSS}" -ne 100 ]];then
      echo -e "入库icmpping状态"
      echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_status&value=1\""
      ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_status&value=1"
      echo -e "\n入库icmpping延迟"
      echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_latency&value=${ICMPPING_LATENCY}\""
      ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_latency&value=${ICMPPING_LATENCY}"
    else 
      echo -e "\n入库icmpping状态"
      echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_status&value=0\""
      ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_status&value=0"
    fi
    echo -e "\n入库icmpping丢包率"
    echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_loss&value=${ICMPPING_LOSS}\""
    ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=icmpping_loss&value=${ICMPPING_LOSS}"
  fi
fi

#处理简单Ping的tcpping监控项
if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|tcpping_status')" ];then

  echo "${ITEM}"|grep -E '^0\|\|tcpping_status'|while read tcp_line
  do
    export KEY_LIST="$(echo "${tcp_line}"|awk -F'[|][|]' '{print $2}')"
    export KEY="$(echo "${KEY_LIST}"|awk -F'[' '{print $1}')"
    export PORT="$(echo "${KEY_LIST}"|awk -F'[' '{print $2}'|awk -F']' '{print $1}')"
    export INTERVAL="$(echo "${tcp_line}"|awk -F'[|][|]' '{print $3}')"

    echo -e "\n--------处理TCPPing监控项:${KEY_LIST}--------"
    if [[ ! -z "$(echo "${KEY}"|grep '^tcpping_status\[')" ]] && [[ ! -z "${PORT}" ]] && [[ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ]];then
      TCPPING=$(timeout 120 nmap -n -P0 -sS -p"${PORT}" "${CLIENT_IP}" 2>&1)
      if [ ! -z "$(echo "${TCPPING}"|grep '/tcp open ')" ];then
        TCPPING_STATUS=1
        echo -e "\n入库${KEY_LIST}状态"
        echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=tcpping_status&key=${KEY_LIST}&value=${TCPPING_STATUS}\""
        ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=tcpping_status&value=${TCPPING_STATUS}"
        TCPPING_LATENCY=$(echo "${TCPPING}"|grep 'latency'|awk '{print $4}'|sed 's/[s|(]//g')
        echo -e "\n入库${KEY_LIST}延迟"
        echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=tcpping_lateny&value=${TCPPING_LATENCY}\""
        ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=tcpping_lateny&value=${TCPPING_LATENCY}"
      else
        TCPPING_STATUS=0
        echo -e "\n入库${KEY_LIST}状态"
        echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=tcpping_status&key=${KEY_LIST}&value=${TCPPING_STATUS}\""
        ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=tcpping_status&value=${TCPPING_STATUS}"
      fi
    fi
  done
fi

#处理简单Ping的udpping监控项
if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|udpping_status')" ];then
  echo "${ITEM}"|grep -E '^0\|\|udpping_status'|while read udp_line
  do
    export KEY_LIST="$(echo "${udp_line}"|awk -F'[|][|]' '{print $2}')"
    export KEY="$(echo "${KEY_LIST}"|awk -F'[' '{print $1}')"
    export PORT="$(echo "${KEY_LIST}"|awk -F'[' '{print $2}'|awk -F']' '{print $1}')"
    export INTERVAL="$(echo "${udp_line}"|awk -F'[|][|]' '{print $3}')"

    echo -e "\n--------处理UDPPing监控项:${KEY_LIST}--------"

    if [[ ! -z "$(echo "${KEY}"|grep '^udpping_status\[')" ]] && [[ ! -z "${PORT}" ]] && [[ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ]];then
      UDPPING=$(timeout 120 nmap -n -P0 -sU -p"${PORT}" "${CLIENT_IP}" 2>&1)
      if [ ! -z "$(echo "${UDPPING}"|grep '/udp open ')" ];then
        UDPPING_STATUS=1
        echo -e "\n入库${KEY_LIST}状态"
        echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=udping_status&value=${UDPPING_STATUS}\""
        ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=udpping_status&value=${UDPPING_STATUS}"
        UDPPING_LATENCY=$(echo "${UDPPING}"|grep 'latency'|awk '{print $4}'|sed 's/[s|(]//g')
        echo -e "\n入库${KEY_LIST}延迟"
        echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=udpping_lateny&value=${UDPPING_LATENCY}\""
        ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=udpping_lateny&value=${UDPPING_LATENCY}"
      else
        UDPPING_STATUS=0
        echo -e "\n入库${KEY_LIST}状态"
        echo "${SEND} -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=udping_status&value=${UDPPING_STATUS}\""
        ${SEND} -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=udpping_status&value=${UDPPING_STATUS}"
      fi
    fi
  done
fi


#获取Ansbile连接信息
export ANSIBLE_HOSTS="${TEMP_DIR}/${HOST_ID}_host"
export ANSIBLE_CMD="timeout 120 ansible -i ${ANSIBLE_HOSTS} all"

if [ ! -s "${ANSIBLE_HOSTS}" ];then
  echo "没有发现ansible hosts文件：${ANSIBLE_HOSTS}"
else
  echo -e "\n--------Anbile命令--------"
  echo "ANSIBLE_CMD=\"timeout 120 ansible -i ${ANSIBLE_HOSTS} all\""
fi

#--------获取SNMP连接信息--------
SNMP_INFO="$(${CURL} ${PROXY}/agent/hostsnmp -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"
snmp_proto=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $1}')
snmp_ip=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $2}')
snmp_port=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $3}')
snmp_community=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $4}')
snmp_user=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $4}')
snmp_security_level=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $5}')
snmp_auth_protocol=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $6}')
snmp_auth_pass=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $7}')
snmp_privacy_protocol=$(echo ${SNMP_INFO}|awk -F'[|][|]' '{print $8}')
snmp_privacy_pass=$(echo ${HOST_SNMP}|awk -F'[|][|]' '{print $9}')

if [ "${snmp_proto}" == 'snmpv1' ];then
    export SNMP_CMD="timeout 120 snmpwalk -v 1 -c ""${snmp_community}"" ""${CLIENT_IP}"
fi

if [ "${snmp_proto}" == 'snmpv2' ];then
    export SNMP_CMD="timeout 120 snmpwalk -v 2c -c ""${snmp_community}"" ""${CLIENT_IP}"
fi

if [ "${snmp_proto}" == 'snmpv3' ];then
    if [ "${snmp_security_level}" == 'noAuthNoPriv' ];then
        export SNMP_CMD="timeout 120 snmpwalk -v 3 -l noAuthNoPriv -u ""${snmp_user}"" ""${CLIENT_IP}"
    fi  
    if [ "${snmp_security_level}" == 'authNoPriv' ];then
        export SNMP_CMD="timeout 120 snmpwalk -v 3 -l authNoPriv -u ""${snmp_user}"" -A ""${snmp_auth_protocol}"" -a '""${snmp_auth_pass}""' ""${CLIENT_IP}"
    fi  
    if [ "${snmp_security_level}" == 'authPriv' ];then
        export SNMP_CMD="timeout 120 snmpwalk -v 3 -l authPriv -u ""${snmp_user}"" -A ""${snmp_auth_protocol}"" -a '""${snmp_auth_pass}""' -X ""${snmp_privacy_protocol}"" -x '""${snmp_privacy_pass}"" ""${CLIENT_IP}"
    fi    
fi

if [ ! -z "$(echo "${SNMP_INFO}"|grep -v 'Incorrect')" ];then
  echo -e "\n--------SNMP命令--------"
  echo "${SNMP_CMD}"
else
  echo "SNMP命令信息不全"
  echo "${CURL} ${PROXY}/agent/hostsnmp -d \"id=${HOST_ID}&ak=${HOST_AK}\""
fi


#第一列IPMI IP、第二列IPMI用户、第三列IPMI密码。
echo -e "\n--------获取IPMI连接信息--------"
IPMI_INFO="$(${CURL} ${PROXY}/agent/hostipmi/get -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"
IPMI_HOST=$(echo "${SNMP_INFO}"|awk -F'[|][|]' '{print $1}')
IPMI_USER=$(echo "${SNMP_INFO}"|awk -F'[|][|]' '{print $2}')
IPMI_PASS=$(echo "${SNMP_INFO}"|awk -F'[|][|]' '{print $3}')

if [[ ! -z "${ipmi_ip}" ]] && [[ ! -z "${ipmi_user}" ]] && [[ ! -z "${ipmi_pass}" ]];then
  echo -e "\n\n--------IPMI命令--------"
  echo "IPMI_CMD="timeout 120 ipmitool -I lan -H ${IPMI_HOST} -U ${IPMI_USER} -P ${IPMI_PASS}""
  export IPMI_CMD="timeout 120 ipmitool -I lan -H ${IPMI_HOST} -U ${IPMI_USER} -P ${IPMI_PASS}"
  echo -e "\n\n--------IPMI命令--------"
  echo "${IPMI_CMD}"
fi

echo -e "\n\n--------处理主机监控项--------"

echo "${ITEM}"|grep -E '^(1|2|3|4|9)\|\|'|while read item_line
do
  export KEY_LIST="$(echo "${item_line}"|awk -F'[|][|]' '{print $2}')"
  export INTERVAL="$(echo "${item_line}"|awk -F'[|][|]' '{print $3}')"
  export LLD_KEY="$(echo "${item_line}"|awk -F'[|][|]' '{print $4}')"
  export TEMPALTE_ID="$(echo "${item_line}"|awk -F'[|][|]' '{print $5}')"
  export ENDPOINT="$(echo "${item_line}"|awk -F'[|][|]' '{print $6}')"

  #如果更新模式是exporter，获取内容
  if [ ! -z "$(echo "${item_line}"|grep ^1)" ];then
    echo "timeout 120 curl -q \"${ENDPOINT}\""
    timeout 120 curl -q "${ENDPOINT}" 2>/dev/null|grep -Ev '^[ \t#]*$' > "${ALL_METRICS}"
    if [ $? -ne 0 ];then
      echo "连接错误，请检查 curl -q ${ENDPOINT}"
      continue
    fi
  fi

  echo -e "\n--------下载Shell--------"
  echo "${CURL} ${PROXY}/agent/mon/shell -d \"id=${HOST_ID}&ak=${HOST_AK}&mon_template_id=${TEMPALTE_ID}\""
  ${CURL} ${PROXY}/agent/mon/shell -d "id=${HOST_ID}&ak=${HOST_AK}&mon_template_id=${TEMPALTE_ID}" 2>&1 >"${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh"

  if [[ ! -z "$(echo "${LLD_KEY}"|grep 'none')" ]] && [[ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ]];then
      echo -e "\n--------处理没有LLD的监控项${item_line}--------"
      echo -e "\n--------调试Shell信息--------"
      echo "export ANSIBLE_CMD=\"${ANSIBLE_CMD}\""
      echo "export SNMP_CMD=\"${SNMP_CMD}\""
      echo "export IPMI_CMD=\"${IPMI_CMD}\""
      echo "export LLD_SEND=\"${LLD_SEND}\""
      echo "export LLD_UPDATE=\"${LLD_UPDATE}\""
      echo "export ALL_METRICS=\"${ALL_METRICS}\""
      echo "export HOST_ID=\"${HOST_ID}\""
      echo "export HOST_AK=${HOST_AK}"
      echo "export SEND=\"${SEND}\""
      echo
      cat ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh
      #执行Shell
      sleep 1
      echo -e "\n\n执行Shell命令：timeout 120 /bin/bash ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh"
      shell_result="$(timeout 120 /bin/bash ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh 2>&1)"
      echo -e "\n\n--------执行Shell结果--------"
      if [ -z "{ALL_METRICS}" ];then
        echo "ALL_METRICS等于空"
      fi
      echo "${shell_result}"
  fi

  if [[ -z "$(echo "${LLD_KEY}"|grep 'none')" ]] && [[ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ]];then
    echo -e "\n--------处理有LLD的监控项${item_line}--------"
    echo "获取发现项"
    echo "${CURL} ${PROXY}/agent/lldvalue/host -d \"id=${HOST_ID}&ak=${HOST_AK}&lld_key=${LLD_KEY}\""
    LLD_VALUE_LIST=$(${CURL} ${PROXY}/agent/lldvalue/host -d "id=${HOST_ID}&ak=${HOST_AK}&lld_key=${LLD_KEY}" 2>&1)
    LLD_VALUE_LIST=$(echo "${LLD_VALUE_LIST}"|sed 's/|/\n/g')
    echo -e "\n发现项内容"
    echo "${LLD_VALUE_LIST}"

    #循环发现项
    echo "${LLD_VALUE_LIST}"|while read lld_value_line
    do
      export LLD_VALUE="${lld_value_line}"
      echo -e "\n--------调试Shell信息--------"
      echo "export ANSIBLE_CMD=\"${ANSIBLE_CMD}\""
      echo "export SNMP_CMD=\"${SNMP_CMD}\""
      echo "export IPMI_CMD=\"${IPMI_CMD}\""
      echo "export LLD_SEND=\"${LLD_SEND}\""
      echo "export LLD_UPDATE=\"${LLD_UPDATE}\""
      echo "export ALL_METRICS=\"${ALL_METRICS}\""
      echo "export HOST_ID=\"${HOST_ID}\""
      echo "export HOST_AK=${HOST_AK}"
      echo "export SEND=\"${SEND}\""
      echo "export LLD_KEY=${LLD_KEY}"
      echo "export LLD_VALUE=${LLD_VALUE}"
      echo
      cat ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh

      #执行Shell
      sleep 1
      echo -e "\n\n执行Shell命令：timeout 120 /bin/bash ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh"
      shell_result="$(timeout 120 /bin/bash ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh 2>&1)"
      echo -e "\n\n--------执行Shell结果--------"
      if [ -z "{ALL_METRICS}" ];then
        echo "ALL_METRICS等于空"
      fi
      echo "${shell_result}"

    done
  fi
done

echo -e "\n--------低级发现--------"

echo "${CURL} ${PROXY}/agent/template/host/lld -d \"id=${HOST_ID}&ak=${HOST_AK}\""
LLD_LIST="$(${CURL} ${PROXY}/agent/template/host/lld -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"

echo -e "\n${LLD_LIST}"
echo -e "第一列发现方式、第二列发现Key、第三列发现间隔、第四列端点。\n"
#发现方式：1Exporter、2Ansible、3SNMP、4IPMI
#例子：2||linux_disk||1||http://192.168:9100/metrics
 

if [ ! -z "${LLD_LIST}" ];then
  echo -e "--------循环处理LLD--------"
  echo "${LLD_LIST}"|sort|uniq|while read lld_line
  do
    export LLD_MODE="$(echo "${lld_line}"|awk -F'[|][|]' '{print $1}')"
    export LLD_KEY="$(echo "${lld_line}"|awk -F'[|][|]' '{print $2}')"
    export LLD_INTERVAL="$(echo "${lld_line}"|awk -F'[|][|]' '{print $3}')"
    export LLD_ENDPOINT="$(echo "${lld_line}"|awk -F'[|][|]' '{print $4}')"

    #如果发现模式是exporter，获取endpoint内容
    if [ ! -z "$(echo "${LLD_MODE}"|grep ^1)" ];then
      echo -e "timeout 120 curl -q \"${LLD_ENDPOINT}\""
      timeout 120 curl -q "${LLD_ENDPOINT}" 2>/dev/null|grep -Ev '^[ \t#]*$' > "${LLD_ALL_METRICS}"
      if [ $? -ne 0 ];then
        echo "连接错误，请检查 curl -q ${LLD_ENDPOINT}"
        continue
      fi
    fi

    echo -e "\n--------下载Shell命令--------"
    echo "${CURL} ${PROXY}/agent/template/host/lld/shell -d \"id=${HOST_ID}&ak=${HOST_AK}&id=${HOST_ID}&lld_key=${LLD_KEY}\""
    ${CURL} ${PROXY}/agent/template/host/lld/shell -d "id=${HOST_ID}&ak=${HOST_AK}&id=${HOST_ID}&lld_key=${LLD_KEY}" 2>&1 >"${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh"

    if [ $((${CUR_SEC} % ${LLD_INTERVAL})) -eq 0 ];then
      echo -e "\n--------调试Shell信息--------"
      echo "export ANSIBLE_CMD=\"${ANSIBLE_CMD}\""
      echo "export SNMP_CMD=\"${SNMP_CMD}\""
      echo "export IPMI_CMD=\"${IPMI_CMD}\""
      echo "export LLD_SEND=\"${LLD_SEND}\""
      echo "export LLD_UPDATE=\"${LLD_UPDATE}\""
      echo "export ALL_METRICS=\"${ALL_METRICS}\""
      echo "export HOST_ID=${HOST_ID}"
      echo "export HOST_AK=${HOST_AK}"
      echo "export SEND=\"${SEND}\""
      echo "export LLD_KEY=${LLD_KEY}"
      echo
      cat ${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh

      #echo "执行Shell命令：timeout 120 /bin/bash ${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh"
      sleep 1
      shell_result="$(timeout 120 /bin/bash ${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh 2>&1)"
      echo -e "\n\n--------执行Shell结果--------"
      if [ -z "{ALL_METRICS}" ];then
        echo "ALL_METRICS等于空"
      fi
      echo "${shell_result}"
    fi
  done
fi


