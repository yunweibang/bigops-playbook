#!/bin/bash

eval $(grep -Ev '^spring_' /opt/bigops/bigproxy/config/bigproxy.properties|grep -Ev '^#')

PROXY="http://127.0.0.1:60001"
TEMP_DIR="/opt/bigops/bigproxy/hostmon_temp"

export HOST_NAME="$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $1}')"
export HOST_ID="$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $2}')"
export HOST_AK="$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $3}')"
export CLIENT_IP=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $4}')
export SYSTEM_CAT=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $5}')
export EXEC_TIME=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $6}')
export CUR_SEC="$(date -d @${EXEC_TIME} "+%M"|sed -r 's/0*([0-9])/\1/')"
export ES_TIME="$(date -d @${EXEC_TIME} "+%Y%m%d")"
export TIMESTAMP="$(date -d @$((${EXEC_TIME}-3600*8)) "+%Y-%m-%dT%H:%M:%S.000Z")"

export CURL="curl -s --connect-timeout 3 -X POST"
export LLD_UPDATE="${CURL} ${PROXY}/agent/discovery/updatenetif"

INT_JSON="${TEMP_DIR}/${HOST_ID}_${EXEC_TIME}_int.json"
DBL_JSON="${TEMP_DIR}/${HOST_ID}_${EXEC_TIME}_dbl.json"

#测试ES连接
for esip in $(echo "${es_ip}"|sed 's/,/\n/g')
do 
  es_status="$(curl --connect-timeout 3 -XGET -u${es_user}:${es_pass} -o /dev/null -s -w %{http_code} http://$esip:${es_port}/_cat/health?v)"
  if [ "${es_status}" == 200 ];then
    break
  fi
done

if [ -z "${esip}" ];then
  echo "Proxy配置文件里的ES配置错误，退出！"
  exit
fi

monitorlog () {
echo -e "\n\n"
curl --connect-timeout 3 -XPOST -u${es_user}:${es_pass} -H "Content-Type: application/json" http://${esip}:${es_port}/monitorlog-$(date +%Y%m%d)/_doc -d \
'{"@timestamp": "'"${TIMESTAMP}"'","proxy": "'"${proxy_name}"'","host_name": "'"${HOST_NAME}"'","host_id": '"${HOST_ID}"',"ip": "'"${CLIENT_IP}"'","msg": "'"${1}"'"}'
}

MULTIPLIE=1

send () {
#例子：send -k in_rate -d "${VALUE1}" -l "${LLD_VALUE}"
echo "send命令：send $@"

if [[ "$1" == "-k" ]] && [[ "$3" == "-d" ]] && [[ ! -z "$(echo "$4"|grep -E '^[0-9\.e\+]+$')" ]] && [[ "$5" == "" ]];then
  if [[ "${DATA_TYPE}" == 1 ]] && [[ "${STORE_TYPE}" == 1 ]];then
    echo "整数原值：DATA_TYPE=${DATA_TYPE},STORE_TYPE=${STORE_TYPE}"
    VALUE="$(echo "$4"|awk '{printf("%d\n",$NF*'"${MULTIPLIE}"')}')"
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"value\": ${VALUE}}" >>"${INT_JSON}"
  elif [[ "${DATA_TYPE}" == 2 ]] && [[ "${STORE_TYPE}" == 1 ]];then
    echo "浮点原值：DATA_TYPE=${DATA_TYPE},STORE_TYPE=${STORE_TYPE}"
    VALUE="$(echo "$4"|awk '{printf("%.2f\n",$NF*'"${MULTIPLIE}"')}')"
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"value\": ${VALUE}}" >>"${DBL_JSON}"
  else
    if [ "${DATA_TYPE}" == 1 ];then
      VALUE="$(echo "$4"|awk '{printf("%d\n",$NF)}')"
    elif [ "${DATA_TYPE}" == 2 ];then
      VALUE="$(echo "$4"|awk '{printf("%.2f\n",$NF)}')"
    fi
    echo "差值或每秒差值：DATA_TYPE=${DATA_TYPE},STORE_TYPE=${STORE_TYPE}"
    echo "${CURL} ${PROXY}/agent/mon/host -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&value=${VALUE}\""
    curl_result=$(${CURL} ${PROXY}/agent/mon/host -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&value=${VALUE}" 2>&1)
    if [ -z "$(echo "${curl_result}"|grep 'code":0')" ];then
      curl_result=$(echo "${curl_result}"|grep 'code":0'|head -n 1)
      monitorlog "curl提交数据错误。接口/agent/mon/host，返回值${curl_result}"
    fi
  fi
elif [[ "$1" == "-k" ]] && [[ "$3" == "-d" ]] && [[ ! -z "$(echo "$4"|grep -E '^[0-9\.e\+]+$')" ]] && [[ "$5" == "-l" ]] && [[ "$6" != "" ]] && [[ "$7" == "" ]];then
  if [[ "${DATA_TYPE}" == 1 ]] && [[ "${STORE_TYPE}" == 1 ]];then
    echo "整数原值：DATA_TYPE=${DATA_TYPE},STORE_TYPE=${STORE_TYPE}"
    VALUE="$(echo "$4"|awk '{printf("%d\n",$NF*'"${MULTIPLIE}"')}')"
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"lld_value\": \"$6\",\"value\": ${VALUE}}" >>"${INT_JSON}"
  elif [[ "${DATA_TYPE}" == 2 ]] && [[ "${STORE_TYPE}" == 1 ]];then
    echo "浮点原值：DATA_TYPE=${DATA_TYPE},STORE_TYPE=${STORE_TYPE}"
    VALUE="$(echo "$4"|awk '{printf("%.2f\n",$NF*'"${MULTIPLIE}"')}')"
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"lld_value\": \"$6\",\"value\": ${VALUE}}" >>"${DBL_JSON}"
  else
    if [ "${DATA_TYPE}" == 1 ];then
      VALUE="$(echo "$4"|awk '{printf("%d\n",$NF)}')"
    elif [ "${DATA_TYPE}" == 2 ];then
      VALUE="$(echo "$4"|awk '{printf("%.2f\n",$NF)}')"
    fi
    echo "差值或每秒差值：DATA_TYPE=${DATA_TYPE},STORE_TYPE=${STORE_TYPE}"
    echo "${CURL} ${PROXY}/agent/mon/host -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&lld_value=$6&value=${VALUE}\""
    curl_result=$(${CURL} ${PROXY}/agent/mon/host -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&lld_value=$6&value=${VALUE}")
    if [ -z "$(echo "${curl_result}"|grep 'code":0')" ];then
      curl_result=$(echo "${curl_result}"|grep 'code":0'|head -n 1)
      monitorlog "curl提交数据错误。接口/agent/mon/host，返回值${curl_result}"
    fi
  fi
else
  echo -e "\n--------send参数错误--------"
  monitorlog "send参数错误。$1 $2 $3 $4 $5 $6"
  echo "$@"
fi
echo
}

send_lld () {
#例子：send_lld -k "linux_disk" -d "${lld_value}"
echo "send_lld命令：send_lld $@"

if [[ "$1" == "-k" ]] && [[ "$3" == "-d" ]] && [[ "$5" == "" ]] ;then
  echo "${CURL} ${PROXY}/agent/discovery/host -d \"id=${HOST_ID}&ak=${HOST_AK}&lld_key=$2&lld_value=${4}\""
  ${CURL} ${PROXY}/agent/discovery/host -d "id=${HOST_ID}&ak=${HOST_AK}&lld_key=$2&lld_value=${4}"
else
  echo -e "\n--------send_lld参数错误--------"
  monitorlog "send_lld参数错误。$1 $2 $3 $4 $5 $6"
  echo "$@"
fi
echo
}

update_netif_status () {
#例子：update_netif_status -i 10001 -d 1
echo "update_netif_status命令：update_netif_status $@"

if [[ "$1" == "-i" ]] && [[ "$3" == "-d" ]] && [[ "$5" == "" ]];then
  echo "${LLD_UPDATE} -d \"id=${HOST_ID}&ak=${HOST_AK}&lld_key=ifDescr&lld_index=${2}&netif_key=netif_status&netif_value=${4}\""
  ${LLD_UPDATE} -d "id=${HOST_ID}&ak=${HOST_AK}&lld_key=ifDescr&lld_index=${2}&netif_key=netif_status&netif_value=${4}"
else
  echo -e "\n--------update_netif_status参数错误--------"
  monitorlog "update_netif_status参数错误。$1 $2 $3 $4 $5 $6"
  echo "$@"
fi
echo
}

update_netif_alias () {
#例子：send_lld -k ifDescr -d 10002|FastEthernet0/2
echo "update_netif_alias命令：update_netif_alias $@"

if [[ "$1" == "-i" ]] && [[ "$3" == "-d" ]] && [[ "$5" == "" ]];then
  echo "${LLD_UPDATE} -d \"id=${HOST_ID}&ak=${HOST_AK}&lld_key=ifDescr&lld_index=${2}&netif_key=netif_alias&netif_value=${4}\""
  ${LLD_UPDATE} -d "id=${HOST_ID}&ak=${HOST_AK}&lld_key=ifDescr=ifDescr&lld_index=${2}&netif_key=netif_alias&netif_value=${4}"
else
  echo -e "\n--------update_netif_alias参数错误--------"
  monitorlog "update_netif_alias参数错误。$1 $2 $3 $4 $5 $6"
  echo "$@"
fi
echo
}

echo "EXEC_TIME：$(date -d @${EXEC_TIME} "+%Y-%m-%d %H:%M:%S")"
START_TIME="$(date "+%Y-%m-%d %H:%M:%S")"
echo "proxy_id：${proxy_id}"
echo "proxy_name：${proxy_name}"
echo "/opt/bigops/bigproxy/hostmon.sh '$@'"

echo -e "\n--------获取监控项列表--------"
echo "${CURL} ${PROXY}/agent/template/host -d \"id=${HOST_ID}&ak=${HOST_AK}\""
ITEM="$(${CURL} ${PROXY}/agent/template/host -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"
if [ $? -ne 0 ];then
  echo "curl超时，退出！"
  monitorlog "curl超时。监控项列表接口/agent/template/host"
  exit
fi

echo -e "\n第1列更新方式、第2列KEY、第3列间隔、第4列自动发现、第5列返回值类型、第6列存储类型、第7列定制倍数、第8列模板ID、第9列端点"
#echo -e "更新方式：0简单Ping、1Exporter、2Ansible、3SNMP、4IPMI、9自定义。"

ITEM="$(echo "${ITEM}"|sed '/^[ \t]*$/d')"
echo -e "${ITEM}\n"

if [ -z "$(echo "${ITEM}"|grep -E '^[0-9]\|\|')" ];then
  echo "错误监控项，退出采集！"
  monitorlog "没有监控项。"
  exit
fi

#处理简单Ping的icmpping监控项
if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|icmpping_status\|\|')" ];then
  INTERVAL="$(echo "${ITEM}"|grep -E '^0\|\|icmpping_status\|\|'|awk -F'[|][|]' 'NR==1{print $3}')"
  if [ "$((${CUR_SEC} % ${INTERVAL}))" -eq 0 ];then
    ICMPPING="$(fping -q -c 2 "${CLIENT_IP}" 2>&1)"
    if [ -z "$(echo "${ICMPPING}"|grep 'xmt/rcv')" ];then
      echo "icmpping超时，退出采集！"
      monitorlog "ping超时。"
      exit
    fi
    ICMPPING_LOSS="$(echo "${ICMPPING}"|awk '/loss/{print $5}'|awk -F/ '{print $NF}'|sed 's/[,|%]//g')"
    ICMPPING_LATENCY="$(echo "${ICMPPING}"|awk '/xmt/{print $NF}'|awk -F/ '{print $2}')"
    echo -e "--------处理icmpping监控项--------"
    if [[ ! -z "${ICMPPING_LOSS}" ]] && [[ "${ICMPPING_LOSS}" -ne 100 ]];then
      STORE_TYPE=1 && DATA_TYPE=1
      send -k icmpping_status -d 1
      if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|icmpping_latency\|\|')" ];then
        STORE_TYPE=1 && DATA_TYPE=2
        send -k icmpping_latency -d "${ICMPPING_LATENCY}"
      fi
    else
      STORE_TYPE=1 && DATA_TYPE=1
      send -k icmpping_status -d 0
    fi
    if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|icmpping_loss\|\|')" ];then
      STORE_TYPE=1 && DATA_TYPE=2
      send -k icmpping_loss -d "${ICMPPING_LOSS}"
    fi
    if [ "${ICMPPING_LOSS}" -eq 100 ];then
      echo "ping丢包率100%，退出采集！"
      monitorlog "ping丢包率100%。"
      exit  
    fi
  fi
fi

#处理简单Ping的tcpping监控项
echo "${ITEM}"|grep -E '^0\|\|tcpping_status\['|while read tcpping_line
do
  KEY_LIST="$(echo "${tcpping_line}"|awk -F'[|][|]' '{print $2}')"
  INTERVAL="$(echo "${tcpping_line}"|awk -F'[|][|]' '{print $3}')"
  echo "${KEY_LIST}"|sed 's/,/\n/g'|while read tcpping_key
  do
    TCPPING_KEY="$(echo ${tcpping_key}|awk -F'[' '{print $1}')"
    TCPPING_PORT="$(echo "${tcpping_key}"|awk -F'[' '{print $2}'|awk -F']' '{print $1}')"
    echo -e "--------处理tcpping监控项:${tcpping_key}--------"
    if [ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ];then
      TCPPING="$(/usr/bin/nmap -n -P0 -sT --host-timeout=5000ms -p${TCPPING_PORT} ${CLIENT_IP} 2>&1)"
      if [ ! -z "$(echo "${TCPPING}"|grep -E '/tcp open ')" ];then
        STORE_TYPE=1 && DATA_TYPE=1
        send -k tcpping_status[${TCPPING_PORT}] -d 1
        TCPPING_LATENCY=$(echo "${TCPPING}"|awk '/latency/{print $4}'|sed 's/[s|(]//g')
        if [ ! -z "$(echo "${ITEM}"|grep -E "tcpping_latency\[${TCPPING_PORT}\]")" ];then
          STORE_TYPE=1 && DATA_TYPE=2
          send -k tcpping_latency[${TCPPING_PORT}] -d "${TCPPING_LATENCY}"
        fi
      else
        STORE_TYPE=1 && DATA_TYPE=1
        send -k tcpping_status[${TCPPING_PORT}] -d 0
      fi
    fi
  done
done

#处理简单Ping的udpping监控项
echo "${ITEM}"|grep -E '^0\|\|udpping_status\['|while read udpping_line
do
  KEY_LIST="$(echo "${udpping_line}"|awk -F'[|][|]' '{print $2}')"
  INTERVAL="$(echo "${udpping_line}"|awk -F'[|][|]' '{print $3}')"
  echo "${KEY_LIST}"|sed 's/,/\n/g'|while read udpping_key
  do
    UDPPING_KEY="$(echo ${udpping_line}|awk -F'[' '{print $1}')"
    UDPPING_PORT="$(echo "${udpping_line}"|awk -F'[' '{print $2}'|awk -F']' '{print $1}')"
    echo -e "--------处理udpping监控项:${udpping_key}--------"
    if [ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ];then
      UDPPING="$(/usr/bin/nmap -n -P0 -sU --host-timeout=5000ms -p${UDPPING_PORT} ${CLIENT_IP} 2>&1)"
      if [ ! -z "$(echo "${UDPPING}"|grep -E '/udp open ')" ];then
        STORE_TYPE=1 && DATA_TYPE=1
        send -k udpping_status[${UDPPING_PORT}] -d 1
        UDPPING_LATENCY=$(echo "${UDPPING}"|awk '/latency/{print $4}'|sed 's/[s|(]//g')
        if [ ! -z "$(echo "${ITEM}"|grep -E "udpping_latency\[${UDPPING_PORT}\]")" ];then
          STORE_TYPE=1 && DATA_TYPE=2
          send -k udpping_lateny[${UDPPING_PORT}] -d "${UDPPING_LATENCY}"
        fi
      else
        STORE_TYPE=1 && DATA_TYPE=1
        send -k udpping_status[${UDPPING_PORT}] -d 0
      fi
    fi
  done
done


#获取Ansbile连接信息
if [ ! -z "$(echo "${ITEM}"|grep -E '^2\|\|')" ];then
  export ANSIBLE_HOSTS=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $6}')
  export ANSIBLE_HOSTS="/opt/bigops/bigproxy/hosts/${HOSTS}"

  if [ ! -f "${ANSIBLE_HOSTS}" ];then
    echo "没有发现ansible hosts文件：${ANSIBLE_HOSTS}"
    monitorlog "没有发现ansible hosts文件。"
  else
    echo -e "\n--------Anbile命令--------"
    echo "ANSIBLE_CMD=\"ansible -i ${ANSIBLE_HOSTS} all\""
    ANSIBLE_CMD="ansible -i ${ANSIBLE_HOSTS} all"
  fi
fi

#获取SNMP连接信息
if [ ! -z "$(echo "${ITEM}"|grep -E '^3\|\|')" ];then
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
      SNMP_CMD="snmpwalk -v 1 -c ""${snmp_community}"" ""${CLIENT_IP}"
  fi

  if [ "${snmp_proto}" == 'snmpv2' ];then
      SNMP_CMD="snmpwalk -v 2c -c ""${snmp_community}"" ""${CLIENT_IP}"
  fi

  if [ "${snmp_proto}" == 'snmpv3' ];then
      if [ "${snmp_security_level}" == 'noAuthNoPriv' ];then
        SNMP_CMD="snmpwalk -v 3 -l noAuthNoPriv -u ""${snmp_user}"" ""${CLIENT_IP}"
      fi  
      if [ "${snmp_security_level}" == 'authNoPriv' ];then
        SNMP_CMD="snmpwalk -v 3 -l authNoPriv -u ""${snmp_user}"" -A ""${snmp_auth_protocol}"" -a '""${snmp_auth_pass}""' ""${CLIENT_IP}"
      fi  
      if [ "${snmp_security_level}" == 'authPriv' ];then
        SNMP_CMD="snmpwalk -v 3 -l authPriv -u ""${snmp_user}"" -A ""${snmp_auth_protocol}"" -a '""${snmp_auth_pass}""' -X ""${snmp_privacy_protocol}"" -x '""${snmp_privacy_pass}"" ""${CLIENT_IP}"
      fi    
  fi

  if [ ! -z "$(echo "${SNMP_INFO}"|grep -v 'Incorrect')" ];then
    echo -e "\n--------SNMP命令--------"
    echo "${SNMP_CMD}"
  else
    echo "SNMP命令信息不全"
    monitorlog "SNMP命令信息不全。"
    echo "${CURL} ${PROXY}/agent/hostsnmp -d \"id=${HOST_ID}&ak=${HOST_AK}\""
  fi
fi

#第一列IPMI IP、第二列IPMI用户、第三列IPMI密码。
if [ ! -z "$(echo "${ITEM}"|grep -E '^4\|\|')" ];then
  echo -e "--------获取IPMI连接信息--------"
  IPMI_INFO="$(${CURL} ${PROXY}/agent/hostipmi/get -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"
  IPMI_HOST=$(echo "${SNMP_INFO}"|awk -F'[|][|]' '{print $1}')
  IPMI_USER=$(echo "${SNMP_INFO}"|awk -F'[|][|]' '{print $2}')
  IPMI_PASS=$(echo "${SNMP_INFO}"|awk -F'[|][|]' '{print $3}')

  if [[ ! -z "${ipmi_ip}" ]] && [[ ! -z "${ipmi_user}" ]] && [[ ! -z "${ipmi_pass}" ]];then
    echo -e "\n\n--------IPMI命令--------"
    echo "IPMI_CMD="ipmitool -I lan -H ${IPMI_HOST} -U ${IPMI_USER} -P ${IPMI_PASS}""
    IPMI_CMD="ipmitool -I lan -H ${IPMI_HOST} -U ${IPMI_USER} -P ${IPMI_PASS}"
    echo -e "\n\n--------IPMI命令--------"
    echo "${IPMI_CMD}"
  else
    monitorlog "IPMI命令信息不全。"
  fi
fi

echo -e "--------处理主机监控项--------"

echo "${ITEM}"|grep -E '^(1|2|3|4|9)\|\|'|while read item_line
do
  KEY="$(echo "${item_line}"|awk -F'[|][|]' '{print $2}')"
  INTERVAL="$(echo "${item_line}"|awk -F'[|][|]' '{print $3}')"
  LLD_KEY="$(echo "${item_line}"|awk -F'[|][|]' '{print $4}')"
  DATA_TYPE="$(echo "${item_line}"|awk -F'[|][|]' '{print $5}')"
  STORE_TYPE="$(echo "${item_line}"|awk -F'[|][|]' '{print $6}')"
  MULTIPLIE="$(echo "${item_line}"|awk -F'[|][|]' '{print $7}')"
  TEMPALTE_ID="$(echo "${item_line}"|awk -F'[|][|]' '{print $8}')"
  ENDPOINT="$(echo "${item_line}"|awk -F'[|][|]' '{print $9}')"

  #如果更新模式是exporter，获取metrics内容
  if [ ! -z "$(echo "${item_line}"|grep ^1)" ];then
    METRICS="$(curl --compressed -q --connect-timeout 3 "${ENDPOINT}" 2>/dev/null|grep -Ev '^[ \t#]*$')"
    if [ $? -ne 0 ];then
      echo "连接错误，请检查 curl --compressed -q ${ENDPOINT}"
      monitorlog "连接错误。curl --compressed -q --connect-timeout 3 \"${ENDPOINT}\""
      continue
    fi
  fi

  echo -e "\n--------下载${KEY}的shell--------"
  echo "${CURL} ${PROXY}/agent/mon/shell -d \"id=${HOST_ID}&ak=${HOST_AK}&mon_template_id=${TEMPALTE_ID}\""
  ${CURL} ${PROXY}/agent/mon/shell -d "id=${HOST_ID}&ak=${HOST_AK}&mon_template_id=${TEMPALTE_ID}" 2>&1 >"${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh"

  if [[ ! -z "$(echo "${LLD_KEY}"|grep 'none')" ]] && [[ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ]];then
    echo -e "\n--------查看${KEY}的shell内容--------"
    cat ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh
    if [ -z "$(/bin/bash -n "${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh")" ];then
      shell_result="$(source ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh 2>&1)"
      if [ ! -z "$(echo "${shell_result}"|grep -E '^[-a-z]+(:|：)')" ];then
        shell_result=$(echo "${shell_result}"|grep -E '^[-a-z]+(:|：)'|head -n 1)
        monitorlog "shell执行错误。${KEY}，${shell_result}"
      fi
      echo -e "\n\n--------执行${KEY}的shell结果--------"
      echo "${shell_result}"
    else
      echo "监控项shell语法错误！"
      monitorlog "监控项shell语法错误。${KEY}"
    fi
  fi

  if [[ -z "$(echo "${LLD_KEY}"|grep 'none')" ]] && [[ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ]];then
    echo -e "\n--------监控项是${KEY}，LLD_KEY是${LLD_KEY}--------"
    echo "获取发现项"
    echo "${CURL} ${PROXY}/agent/lldvalue/host -d \"id=${HOST_ID}&ak=${HOST_AK}&lld_key=${LLD_KEY}\""
    LLD_VALUE_LIST=$(${CURL} ${PROXY}/agent/lldvalue/host -d "id=${HOST_ID}&ak=${HOST_AK}&lld_key=${LLD_KEY}" 2>&1)
    LLD_VALUE_LIST=$(echo "${LLD_VALUE_LIST}"|sed 's/|/\n/g')
    echo -e "\n发现项内容"
    echo -e "${LLD_VALUE_LIST}\n"

    #循环发现项
    echo "${LLD_VALUE_LIST}"|while read lld_value_line
    do
      LLD_INDEX=$(echo "${lld_value_line}"|awk -F',' '{print $2}')
      LLD_VALUE=$(echo "${lld_value_line}"|awk -F',' '{print $1}')

      echo -e "\n--------查看${KEY}，${LLD_VALUE}的shell内容--------"
      cat ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh
      if [ -z "$(/bin/bash -n "${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh")" ];then
        shell_result="$(source ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh 2>&1)"
        if [ ! -z "$(echo "${shell_result}"|grep -E '^[-a-z]+(:|：)')" ];then
          shell_result=$(echo "${shell_result}"|grep -E '^[-a-z]+(:|：)'|head -n 1)
          monitorlog "shell执行错误。${KEY}，${shell_result}"
        fi
        echo -e "\n--------执行${KEY}，${LLD_VALUE}的shell结果--------"
        echo "${shell_result}"
      else
        echo "发现项shell语法错误！"
        monitorlog "shell语法错误。${KEY}，${LLD_VALUE}"
      fi
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
    LLD_MODE="$(echo "${lld_line}"|awk -F'[|][|]' '{print $1}')"
    LLD_KEY="$(echo "${lld_line}"|awk -F'[|][|]' '{print $2}')"
    LLD_INTERVAL="$(echo "${lld_line}"|awk -F'[|][|]' '{print $3}')"
    LLD_ENDPOINT="$(echo "${lld_line}"|awk -F'[|][|]' '{print $4}')"

    #如果发现模式是exporter，获取endpoint内容
    if [ ! -z "$(echo "${LLD_MODE}"|grep ^1)" ];then
      echo -e "curl --compressed -q --connect-timeout 3 \"${LLD_ENDPOINT}\""
	    METRICS="$(curl --compressed -q --connect-timeout 3 "${LLD_ENDPOINT}" 2>/dev/null|grep -Ev '^[ \t#]*$')"
      if [ $? -ne 0 ];then
         echo "连接错误，请检查 curl --compressed -q ${LLD_ENDPOINT}"
         monitorlog "连接错误。curl --compressed -q ${LLD_ENDPOINT}"
         continue
       fi
    fi

    echo -e "\n--------下载${lld_line}的shell命令--------"
    echo "${CURL} ${PROXY}/agent/template/host/lld/shell -d \"id=${HOST_ID}&ak=${HOST_AK}&id=${HOST_ID}&lld_key=${LLD_KEY}\""
    ${CURL} ${PROXY}/agent/template/host/lld/shell -d "id=${HOST_ID}&ak=${HOST_AK}&id=${HOST_ID}&lld_key=${LLD_KEY}" 2>&1 >"${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh"

    if [ $((${CUR_SEC} % ${LLD_INTERVAL})) -eq 0 ];then
      echo -e "\n--------查看${lld_line}的shell内容--------"
      cat "${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh"
      if [ -z "$(/bin/bash -n "${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh")" ];then
        shell_result="$(source ${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh 2>&1)"
        if [ ! -z "$(echo "${shell_result}"|grep -E '^[-a-z]+(:|：)')" ];then
          shell_result=$(echo "${shell_result}"|grep -E '^[-a-z]+(:|：)'|head -n 1)
          monitorlog "shell执行错误。${KEY}，${shell_result}"
        fi
        echo -e "\n--------执行${lld_line}的shell结果--------"
        echo "${shell_result}"
      else
        echo "shell语法错误！"
        monitorlog "shell语法错误。${lld_line}"
      fi
      echo -e "\n--------执行${lld_line}的shell结果--------"
      echo "${shell_result}"
    fi
  done
fi

echo -e "\n-----------提交INT数据--------------"
cat "${INT_JSON}"
if [ -s "${INT_JSON}" ];then
  curl_result=$(curl --connect-timeout 3 -s -XPOST -u${es_user}:${es_pass} -H "Content-Type: application/json" http://${esip}:${es_port}/monitor-history-int-${ES_TIME}/_doc/_bulk --data-binary @${INT_JSON} 2>&1)
  echo "${curl_result}"
  if [ -z "$(echo "${curl_result}"|grep successful|grep 'failed":0')" ];then
    monitorlog "curl提交es整数错误。"
  fi
fi

echo -e "\n\n-----------提交DBL数据--------------"
cat "${DBL_JSON}"
if [ -s "${DBL_JSON}" ];then
  curl_result=$(curl --connect-timeout 3 -s -XPOST -u${es_user}:${es_pass} -H "Content-Type: application/json" http://${esip}:${es_port}/monitor-history-dbl-${ES_TIME}/_doc/_bulk --data-binary @${DBL_JSON} 2>&1)
  echo "${curl_result}"
  if [ -z "$(echo "${curl_result}"|grep successful|grep 'failed":0')" ];then
    monitorlog "curl提交es浮点错误。"
  fi
fi

rm -f ${INT_JSON} ${DBL_JSON}

START_TIME1=$(date -d "${START_TIME}" +%s)
END_TIME=$(date +%s)
TIME=$(echo ${START_TIME1} ${END_TIME}|awk '{print $2-$1}')
echo -e "\n\n开始时间：${START_TIME}"
echo "结束时间：$(date -d @${END_TIME} +'%Y-%m-%d %H:%M:%S')"
echo "耗时：${TIME}秒"

if [ "${TIME}" -gt 30 ];then
  monitorlog "采集时间超过30秒。耗时${TIME}秒。"
fi

