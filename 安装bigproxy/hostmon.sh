#!/bin/bash

eval $(grep -Ev '^spring_' /opt/bigops/bigproxy/config/bigproxy.properties|grep -Ev '^#')

PROXY="http://127.0.0.1:60001"
TEMP_DIR="/opt/bigops/bigproxy/hostmon_temp"

export HOST_ID="$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $1}')"
HOST_AK="$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $2}')"
export CLIENT_IP=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $3}')
export SYSTEM_CAT=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $4}')
export EXEC_TIME=$(echo "$1"|sed "s/'//g"|awk -F'|' '{print $5}')
export CUR_SEC="$(date -d @${EXEC_TIME} "+%M"|sed -r 's/0*([0-9])/\1/')"
TIMESTAMP="$(date -d @$((${EXEC_TIME}-3600*8)) "+%Y-%m-%dT%H:%M:%S.000Z")"
ES_TIME="$(date -d @${EXEC_TIME} "+%Y%m%d")"

export CURL="curl -s --connect-timeout 15 -X POST"
export LLD_UPDATE="${CURL}"" ${PROXY}/agent/discovery/updatenetif"

if [[ -z "${HOST_ID}" ]] || [[ -z "${HOST_AK}" ]] || [[ -z "${CLIENT_IP}" ]] || [[ -z "${EXEC_TIME}" ]];then
    echo "HOST_ID、HOST_AK、CLIENT_IP、EXEC_TIME有一项为空"
    exit
fi

>${TEMP_DIR}/int.json
>${TEMP_DIR}/dbl.json

send () {
#例子：send -k "in_rate" -v "${VALUE1}" -l "${LLD_VALUE}"
echo "执行的send命令"
echo "send $@"
if [[ "$1" == "-k" ]] && [[ "$3" == "-v" ]] && [[ ! -z "$(echo "$4"|grep -E '^[0-9\.e\+]+$')" ]] && [[ "$5" == "" ]] ;then
  VALUE="$(echo "$4"|awk '{printf("%.2f\n",$NF)}')"
  if [ ! -z "$(echo "$2"|grep -E '^(icmpping_status|tcpping_status|udpping_status|proc_total|proc_running|proc_zombie|tcp_total|tcp_estab|tcp_synrecv|tcp_timewait|disk_fs_max_usage|disk_inode_max_usage)')" ];then
    VALUE="$(echo "$4"|awk '{printf("%d\n",$NF)}')"
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"value\": ${VALUE}}" >>${TEMP_DIR}/int.json
  elif [ ! -z "$(echo "$2"|grep -E '^(icmpping_latency|icmpping_loss|tcpping_latency|udpping_latency|cpu_usage|mem_usage)')" ];then
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"value\": ${VALUE}}" >>${TEMP_DIR}/dbl.json    
  else
    echo "${CURL} ${PROXY}/agent/mon/host -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&value=${VALUE}\""
    ${CURL} ${PROXY}/agent/mon/host -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&value=${VALUE}"
  fi
elif [[ "$1" == "-k" ]] && [[ "$3" == "-v" ]] && [[ ! -z "$(echo "$4"|grep -E '^[0-9\.e\+]+$')" ]] && [[ "$5" == "-l" ]] && [[ "$6" != "" ]] && [[ "$7" == "" ]];then
  VALUE="$(echo "$4"|awk '{printf("%.2f\n",$NF)}')"
  if [ ! -z "$(echo "$2"|grep -E '^(disk_fs_usage|disk_inode_usage)')" ];then
    VALUE="$(echo "$4"|awk '{printf("%d\n",$NF)}')"
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"lld_value\": \"$6\",\"value\": ${VALUE}}" >>${TEMP_DIR}/int.json
  elif [ ! -z "$(echo "$2"|grep -E '^(xxxxxx|xxxxxx)')" ];then
    echo -e "{\"create\" : {}}\n{\"instance_id\": ${HOST_ID},\"@timestamp\": \"${TIMESTAMP}\",\"clock\": ${EXEC_TIME},\"type\": \"monhost\",\"item_key\": \"$2\",\"lld_value\": \"$6\",\"value\": ${VALUE}}" >>${TEMP_DIR}/dbl.json    
  else
    echo "${CURL} ${PROXY}/agent/mon/host -d \"id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&lld_value=$6&value=${VALUE}\""
    ${CURL} ${PROXY}/agent/mon/host -d "id=${HOST_ID}&ak=${HOST_AK}&exec_time=${EXEC_TIME}&key=$2&lld_value=$6&value=${VALUE}"
  fi
else
  echo -e "\n--------send参数错误--------"
  echo "$@"
fi
echo
}

export -f send

send_lld () {
#例子：send_lld -k "linux_disk" -v "${lld_value}"
echo "执行的send_lld命令"
echo "send_lld $@"
if [[ "$1" == "-k" ]] && [[ "$3" == "-v" ]] && [[ "$5" == "" ]] ;then
  echo "${CURL} ${PROXY}/agent/discovery/host -d \"id=${HOST_ID}&ak=${HOST_AK}&lld_key=$2&lld_value=${4}\""
  ${CURL} ${PROXY}/agent/discovery/host -d "id=${HOST_ID}&ak=${HOST_AK}&lld_key=$2&lld_value=${4}"
else
  echo -e "\n--------send_lld参数错误--------"
  echo "$@"
fi
}

export -f send_lld

echo "EXEC_TIME：$(date -d @${EXEC_TIME} "+%Y-%m-%d %H:%M:%S")"
echo "START_TIME：$(date "+%Y-%m-%d %H:%M:%S")"
echo "proxy_id：${proxy_id}"
echo "proxy_name：${proxy_name}"
echo "/opt/bigops/bigproxy/hostmon.sh '$@'"

echo -e "\n--------获取监控项列表--------"
echo "${CURL} ${PROXY}/agent/template/host -d \"id=${HOST_ID}&ak=${HOST_AK}\""
ITEM="$(${CURL} ${PROXY}/agent/template/host -d "id=${HOST_ID}&ak=${HOST_AK}" 2>&1)"
if [ $? -ne 0 ];then
  echo "curl超时，退出！"
  exit
fi

echo -e "\n第一列更新方式、第二列KEY、第三列间隔、第四列自动发现、第五列模板ID、第六列端点"
#例子：1||mem_usage,cpu_usage||1||none||11||http://172.31.173.25:9100/metrics
#echo -e "更新方式：0简单Ping、1Exporter、2Ansible、3SNMP、4IPMI、9自定义。"

ITEM="$(echo "${ITEM}"|sed '/^[ \t]*$/d')"
echo -e "${ITEM}\n"

if [ -z "$(echo "${ITEM}"|grep -E '^[0-9]\|\|')" ];then
  echo "错误监控项，退出采集！"
  exit
fi

#处理简单Ping的icmpping监控项
if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|icmpping_status\|\|')" ];then
  INTERVAL="$(echo "${ITEM}"|grep -E '^0\|\|icmpping_status\|\|'|awk -F'[|][|]' 'NR==1{print $3}')"
  if [ "$((${CUR_SEC} % ${INTERVAL}))" -eq 0 ];then
    ICMPPING="$(fping -q -c 2 "${CLIENT_IP}" 2>&1)"
    if [ -z "$(echo "${ICMPPING}"|grep 'xmt/rcv')" ];then
      echo "icmpping超时，退出采集！"
      exit
    fi
    ICMPPING_LOSS="$(echo "${ICMPPING}"|awk '/loss/{print $5}'|awk -F/ '{print $NF}'|sed 's/[,|%]//g')"
    ICMPPING_LATENCY="$(echo "${ICMPPING}"|awk '/xmt/{print $NF}'|awk -F/ '{print $2}')"
    echo -e "--------处理icmpping监控项--------"
    if [[ ! -z "${ICMPPING_LOSS}" ]] && [[ "${ICMPPING_LOSS}" -ne 100 ]];then
      send -k icmpping_status -v 1
      if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|icmpping_latency\|\|')" ];then
        send -k icmpping_latency -v ${ICMPPING_LATENCY}
      fi
    else 
      send -k icmpping_status -v 0
    fi
    if [ ! -z "$(echo "${ITEM}"|grep -E '^0\|\|icmpping_loss\|\|')" ];then
      send -k icmpping_loss -v ${ICMPPING_LOSS}
    fi
    if [ "${ICMPPING_LOSS}" -eq 100 ];then
      echo "丢包率等于100%，退出采集！"
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
        send -k tcpping_status[${TCPPING_PORT}] -v 1
        TCPPING_LATENCY=$(echo "${TCPPING}"|awk '/latency/{print $4}'|sed 's/[s|(]//g')
        if [ ! -z "$(echo "${ITEM}"|grep -E "tcpping_latency\[${TCPPING_PORT}\]")" ];then
          send -k tcpping_latency[${TCPPING_PORT}] -v ${TCPPING_LATENCY}
        fi
      else
        send -k tcpping_status[${TCPPING_PORT}] -v 0
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
        send -k udpping_status[${UDPPING_PORT}] -v 1
        UDPPING_LATENCY=$(echo "${UDPPING}"|awk '/latency/{print $4}'|sed 's/[s|(]//g')
        if [ ! -z "$(echo "${ITEM}"|grep -E "udpping_latency\[${UDPPING_PORT}\]")" ];then
          send -k udpping_lateny[${UDPPING_PORT}] -v ${UDPPING_LATENCY}
        fi
      else
        send -k udpping_status[${UDPPING_PORT}] -v 0
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
  else
    echo -e "\n--------Anbile命令--------"
    echo "ANSIBLE_CMD=\"ansible -i ${ANSIBLE_HOSTS} all\""
    export ANSIBLE_CMD="ansible -i ${ANSIBLE_HOSTS} all"
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
      export SNMP_CMD="snmpwalk -v 1 -c ""${snmp_community}"" ""${CLIENT_IP}"
  fi

  if [ "${snmp_proto}" == 'snmpv2' ];then
      export SNMP_CMD="snmpwalk -v 2c -c ""${snmp_community}"" ""${CLIENT_IP}"
  fi

  if [ "${snmp_proto}" == 'snmpv3' ];then
      if [ "${snmp_security_level}" == 'noAuthNoPriv' ];then
          export SNMP_CMD="snmpwalk -v 3 -l noAuthNoPriv -u ""${snmp_user}"" ""${CLIENT_IP}"
      fi  
      if [ "${snmp_security_level}" == 'authNoPriv' ];then
          export SNMP_CMD="snmpwalk -v 3 -l authNoPriv -u ""${snmp_user}"" -A ""${snmp_auth_protocol}"" -a '""${snmp_auth_pass}""' ""${CLIENT_IP}"
      fi  
      if [ "${snmp_security_level}" == 'authPriv' ];then
          export SNMP_CMD="snmpwalk -v 3 -l authPriv -u ""${snmp_user}"" -A ""${snmp_auth_protocol}"" -a '""${snmp_auth_pass}""' -X ""${snmp_privacy_protocol}"" -x '""${snmp_privacy_pass}"" ""${CLIENT_IP}"
      fi    
  fi

  if [ ! -z "$(echo "${SNMP_INFO}"|grep -v 'Incorrect')" ];then
    echo -e "\n--------SNMP命令--------"
    echo "${SNMP_CMD}"
  else
    echo "SNMP命令信息不全"
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
    export IPMI_CMD="ipmitool -I lan -H ${IPMI_HOST} -U ${IPMI_USER} -P ${IPMI_PASS}"
    echo -e "\n\n--------IPMI命令--------"
    echo "${IPMI_CMD}"
  fi
fi

echo -e "--------处理主机监控项--------"

echo "${ITEM}"|grep -E '^(1|2|3|4|9)\|\|'|while read item_line
do
  KEY="$(echo "${item_line}"|awk -F'[|][|]' '{print $2}')"
  INTERVAL="$(echo "${item_line}"|awk -F'[|][|]' '{print $3}')"
  LLD_KEY="$(echo "${item_line}"|awk -F'[|][|]' '{print $4}')"
  TEMPALTE_ID="$(echo "${item_line}"|awk -F'[|][|]' '{print $8}')"
  ENDPOINT="$(echo "${item_line}"|awk -F'[|][|]' '{print $9}')"

  #如果更新模式是exporter，获取metrics内容
  if [ ! -z "$(echo "${item_line}"|grep ^1)" ];then
    export METRICS="$(curl --compressed -q --connect-timeout 15 "${ENDPOINT}" 2>/dev/null|grep -Ev '^[ \t#]*$')"
    if [ $? -ne 0 ];then
      echo "连接错误，请检查 curl --compressed -q ${ENDPOINT}"
      continue
    fi
  fi

  echo -e "\n--------下载${KEY}的Shell--------"
  echo "${CURL} ${PROXY}/agent/mon/shell -d \"id=${HOST_ID}&ak=${HOST_AK}&mon_template_id=${TEMPALTE_ID}\""
  ${CURL} ${PROXY}/agent/mon/shell -d "id=${HOST_ID}&ak=${HOST_AK}&mon_template_id=${TEMPALTE_ID}" 2>&1 >"${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh"

  if [[ ! -z "$(echo "${LLD_KEY}"|grep 'none')" ]] && [[ $((${CUR_SEC} % ${INTERVAL})) -eq 0 ]];then
    echo "export ANSIBLE_CMD=\"${ANSIBLE_CMD}\""
    echo "export SNMP_CMD=\"${SNMP_CMD}\""
    echo "export IPMI_CMD=\"${IPMI_CMD}\""
    echo -e "\n--------查看${KEY}的Shell内容--------"
    cat ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh
    shell_result="$(source ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh 2>&1)"
    echo -e "\n--------执行${KEY}的Shell结果--------"
    echo "${shell_result}"
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
      export LLD_VALUE="${lld_value_line}"
      echo "export ANSIBLE_CMD=\"${ANSIBLE_CMD}\""
      echo "export SNMP_CMD=\"${SNMP_CMD}\""
      echo "export IPMI_CMD=\"${IPMI_CMD}\""
      echo -e "\n--------查看${KEY}，${LLD_VALUE}的Shell内容--------"
      cat ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh
      shell_result="$(source ${TEMP_DIR}/${HOST_ID}_${TEMPALTE_ID}.sh 2>&1)"
      echo -e "\n--------执行${KEY}，${LLD_VALUE}的Shell结果--------"
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
      echo -e "curl --compressed -q --connect-timeout 15 \"${LLD_ENDPOINT}\""
	    export LLD_METRICS="$(curl --compressed -q --connect-timeout 15 "${LLD_ENDPOINT}" 2>/dev/null|grep -Ev '^[ \t#]*$')"
      if [ $? -ne 0 ];then
         echo "连接错误，请检查 curl --compressed -q ${LLD_ENDPOINT}"
         continue
       fi
    fi

    echo -e "\n--------下载${lld_line}的Shell命令--------"
    echo "${CURL} ${PROXY}/agent/template/host/lld/shell -d \"id=${HOST_ID}&ak=${HOST_AK}&id=${HOST_ID}&lld_key=${LLD_KEY}\""
    ${CURL} ${PROXY}/agent/template/host/lld/shell -d "id=${HOST_ID}&ak=${HOST_AK}&id=${HOST_ID}&lld_key=${LLD_KEY}" 2>&1 >"${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh"

    if [ $((${CUR_SEC} % ${LLD_INTERVAL})) -eq 0 ];then
      echo "export ANSIBLE_CMD=\"${ANSIBLE_CMD}\""
      echo "export SNMP_CMD=\"${SNMP_CMD}\""
      echo "export IPMI_CMD=\"${IPMI_CMD}\""
      echo -e "\n--------查看${lld_line}的Shell内容--------"
      cat "${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh"
      shell_result="$(source ${TEMP_DIR}/${HOST_ID}_${LLD_KEY}.sh 2>&1)"
      echo -e "\n--------执行${lld_line}的Shell结果--------"
      echo "${shell_result}"
    fi
  done
fi

echo -e "\n-----------提交INT数据--------------"
cat "${TEMP_DIR}/int.json"
if [ -s "${TEMP_DIR}/int.json" ];then
  echo "curl -s -XPOST -u${es_user}:${es_pass} -H \"Content-Type: application/json\" http://${es_ip}:${es_port}/monitor-history-int-${ES_TIME}/_doc/_bulk --data-binary @${TEMP_DIR}/int.json"
  curl -s -XPOST -u${es_user}:${es_pass} -H "Content-Type: application/json" http://${es_ip}:${es_port}/monitor-history-int-${ES_TIME}/_doc/_bulk --data-binary @${TEMP_DIR}/int.json
fi

echo -e "\n\n-----------提交DBL数据--------------"

cat "${TEMP_DIR}/dbl.json"
if [ -s "${TEMP_DIR}/dbl.json" ];then
  echo "curl -s -XPOST -u${es_user}:${es_pass} -H \"Content-Type: application/json\" http://${es_ip}:${es_port}/monitor-history-dbl-${ES_TIME}/_doc/_bulk --data-binary @${TEMP_DIR}/dbl.json"
  curl -s -XPOST -u${es_user}:${es_pass} -H "Content-Type: application/json" http://${es_ip}:${es_port}/monitor-history-dbl-${ES_TIME}/_doc/_bulk --data-binary @${TEMP_DIR}/dbl.json
fi

echo -e "\n\nEND_TIME：$(date "+%Y-%m-%d %H:%M:%S")"

