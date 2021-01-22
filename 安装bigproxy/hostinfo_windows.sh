#!/bin/bash

SETUP=$(${ANSIBLE_CMD} -m setup)

echo "${SETUP}"

echo "${SETUP}" >${TEMP_DIR}/${HOST_ID}_setup
DISK=$(${ANSIBLE_CMD} -m win_disk_facts)
echo "${DISK}" >${TEMP_DIR}/${HOST_ID}_disk

if [ -z "$(echo "${SETUP}"|grep -E '(CHANGED|SUCCESS)')" ];then
    echo "执行错误，退出！"
    exit
fi

nodename=$(echo "${SETUP}"|grep -E '"ansible_nodename":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
cpu_count=$(echo "${SETUP}"|grep -E '"ansible_processor_count":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
cpu_cores=$(echo "${SETUP}"|grep -E '"ansible_processor_cores":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
vcpus=$(echo "${SETUP}"|grep -E '"ansible_processor_vcpus":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
mem_total=$(echo "${SETUP}"|grep -E '"ansible_memtotal_mb":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
disk_total=$(echo "${DISK}"|awk  '/physical_disk/,/},/'|grep '"size":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g'|awk '{sum += $1};END {print int(sum/1024/1024)}')
architecture=$(echo "${SETUP}"|grep -E '"ansible_architecture":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
kernel=$(echo "${SETUP}"|grep -E '"ansible_kernel":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
distribution=$(echo "${SETUP}"|grep -E '"ansible_distribution":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
distribution_major_version=$(echo "${SETUP}"|grep -E '"ansible_distribution_major_version":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
distribution_version=$(echo "${SETUP}"|grep -E '"ansible_distribution_version":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
lan_ip=$(echo "${SETUP}"|awk  '/ansible_ip_addresses/,/],/'|sed -r 's/("|,)//g'|sed -r 's/^ *//g'|sed 's/^[ ]*//g'|grep -E '^(192|172|10|18)\.'|uniq|sort)
wan_ip=$(echo "${SETUP}"|awk  '/ansible_ip_addresses/,/],/'|sed -r 's/("|,)//g'|sed -r 's/^ *//g'|sed 's/^[ ]*//g'|grep -Ev '^(192|172|10|18|127|[a-z]|:|])'|uniq|sort)
product_vendor=$(echo "${SETUP}"|grep -E '"ansible_system_vendor":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
product_name=$(echo "${SETUP}"|grep -E '"ansible_product_name":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')
product_serial=$(echo "${SETUP}"|grep -E '"ansible_product_serial":'|awk -F: '{print $2}'|sed -r 's/("|,)//g'|sed -r 's/^ *//g')


HOSTINFO="{
\"nodename\": \"${nodename}\",
\"cpu_count\": ${cpu_count},
\"cpu_cores\": ${cpu_cores},
\"vcpus\": ${vcpus},
\"mem_total\": ${mem_total},
\"disk_total\": ${disk_total},
\"architecture\": \"${architecture}\",
\"kernel\": \"${kernel}\",
\"distribution\": \"${distribution}\",
\"distribution_major_version\": \"${distribution_major_version}\",
\"distribution_version\": \"${distribution_version}\",
\"lan_ip\": \"${lan_ip}\",
\"wan_ip\": \"${wan_ip}\",
\"product_vendor\": \"${product_vendor}\",
\"product_name\": \"${product_name}\",
\"product_serial\": \"${product_serial}\"
}"

# echo "${HOSTINFO}"

if [ ! -z "${HOSTINFO}" ];then
	echo "${CURL} ${PROXY}/agent/hostinfo -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"hostinfo=${HOSTINFO}\""
	${CURL} ${PROXY}/agent/hostinfo -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "hostinfo=${HOSTINFO}"
	echo -e "\n\n"
fi

#配置详情，内存信息
MEM=$(${ANSIBLE_CMD} -m raw -a "wmic memorychip get Capacity,DeviceLocator,Manufacturer,PartNumber,SerialNumber,Speed /value")

MEM=$(echo "${MEM}"|dos2unix|dos2unix|awk '/Capacity/,0'|awk -F= '\
{if ($1 ~ /^Capacity/) printf("%s||",$2/1024/1024" MB")};\
{if ($1 ~ /^DeviceLocator/) printf("%s||",$2)};\
{if ($1 ~ /^Manufacturer/) printf("%s||",$2)};\
{if ($1 ~ /^PartNumber/) printf("%s||",$2)};\
{if ($1 ~ /^SerialNumber/) printf("%s||",$2)};\
{if ($1 ~ /^Speed/) printf("%s\n",$2)};' \
|awk -F'[|][|]' '{print $1"||"$2"||RAM||"$6"||"$3"||"$5"||"$4" ||"}')

#echo "${MEM}"

if [ ! -z "${MEM}" ];then
  echo "${CURL} ${PROXY}/agent/hostmem -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"mem=${MEM}\""
  ${CURL} ${PROXY}/agent/hostmem -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "mem=${MEM}"
  echo -e "\n\n"
fi


CPU=$(${ANSIBLE_CMD} -m raw -a "wmic cpu get Name,NumberOfLogicalProcessors,CurrentClockSpeed /value")
PCPU=$(echo "${CPU}"|dos2unix|dos2unix|grep '^Name'|sort|uniq|wc -l)
CORES="$(echo "${CPU}"|dos2unix|dos2unix|grep '^NumberOfCores'|awk -F= '{print $2}'|head -n 1)"
LCPU="$(echo "${CPU}"|dos2unix|dos2unix|grep '^NumberOfLogicalProcessors'|awk -F= '{print $2}'|head -n 1)"
SPEED="$(echo "${CPU}"|dos2unix|dos2unix|grep '^CurrentClockSpeed'|awk -F= '{print $2}'|head -n 1)"

#物理*核数*2=逻辑
if [ "$((${PCPU}*${CORES}*2))" = "${LCPU}" ];then
  HT="启用"
else
	HT="禁用"
fi

CPUSTATS=$(echo "${PCPU}||${LCPU}||${HT}||${SPEED}")

if [ ! -z "${CPUSTATS}" ];then
  echo "${CURL} ${PROXY}/agent/hostcpustats -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"cpustats=${CPUSTATS}\""
  ${CURL} ${PROXY}/agent/hostcpustats -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "cpustats=${CPUSTATS}"
  echo -e "\n\n"
fi

#配置详情，CPU，格式：socket||model||core_count||ht

CPU="$(${ANSIBLE_CMD} -m raw -a "wmic cpu get Name,NumberOfCores,SocketDesignation,Status /value")"

CPU="$(echo "${CPU}"|dos2unix|dos2unix|awk '/Name/,0'|awk -F= '\
{if ($1 ~ /^Name/) printf("%s||",$2)};\
{if ($1 ~ /^NumberOfCores/) printf("%s||",$2)};\
{if ($1 ~ /^SocketDesignation/) printf("%s\n",$2)};' \
|awk -F'[|][|]' '{print $3"||"$1"||"$2"}'|awk '{print $0"||""'${HT}'"}')"

#echo "${CPU}"

if [ ! -z "${CPU}" ];then
  echo "${CURL} ${PROXY}/agent/hostcpu -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"cpu=${CPU}\""
	${CURL} ${PROXY}/agent/hostcpu -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "cpu=${CPU}"
  echo -e "\n\n"
fi


#配置详情，NIC，格式：name||mac||speed||status
NIC="$(${ANSIBLE_CMD} -m raw -a "wmic nic get Name,MACAddress,Speed,NetConnectionStatus /value")"

NIC=$(echo "${NIC}"|dos2unix|dos2unix|awk '/MACAddress/,0'|awk -F= '\
{if ($1 ~ /^MACAddress/) printf("%s||",$2)};\
{if ($1 ~ /^Name/) printf("%s||",$2)};\
{if ($1 ~ /^NetConnectionStatus/) printf("%s||",$2)};\
{if ($1 ~ /^Speed/) printf("%s\n",$2)};' \
|awk -F'[|][|]' '{print $2"||"$1"||||"$4/1000000"Mb/s||"$3}' \
|grep 'Ethernet')

NIC="$(echo "${NIC}"|sed "s/2$/UP/g")"

if [ ! -z "{NIC}" ];then
  echo "${CURL} ${PROXY}/agent/hostnic -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"nic=${NIC}\""
	${CURL} ${PROXY}/agent/hostnic -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "nic=${NIC}"
  echo -e "\n\n"
fi


#配置详情，磁盘分区
DISKPART=$(echo "${DISK}"|dos2unix|dos2unix|awk '/partitions/,/physical_disk/'| \
grep -E '"(drive_letter|label|size|size_remaining)' |awk -F': ' '\
{if ($1 ~ /"drive_letter"/) printf("%s||",$2)};\
{if ($1 ~ /"label"/) printf("%s||",$2)};\
{if ($1 ~ /"size"/) printf("%s||",$2)};\
{if ($1 ~ /"size_remaining"/) printf("%s\n",$2)};' \
|sed 's/,//g'|sed 's/"//g'|awk -F'[|][|]' '{print $1":||"int($4/1024/1024/1024)"GB||"int(($4-$5)/1024/1024/1024)"GB||"int($5/$4*100)"||"$3}')

if [ ! -z "${DISKPART}" ];then
  echo "${CURL} ${PROXY}/agent/hostdiskpart -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"diskpart=${DISKPART}\""
  ${CURL} ${PROXY}/agent/hostdiskpart -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "diskpart=${DISKPART}"
  echo -e "\n\n"
fi


#配置详情，虚拟盘
LDISK=$(echo "${DISK}"|dos2unix|dos2unix|awk '/physical_disk/,/read_only/'| \
grep -E '"(manufacturer|model|bus_type|size)' |awk -F': ' '\
{if ($1 ~ /"bus_type"/) printf("%s||",$2)};\
{if ($1 ~ /"manufacturer"/) printf("%s||",$2)};\
{if ($1 ~ /"model"/) printf("%s||",$2)};\
{if ($1 ~ /"size"/) printf("%s\n",$2)};' \
|sed 's/,//g'|sed 's/"//g'|awk -F'[|][|]' '{print $2$3,$1"||"int($4/1024/1024/1024)"GB"}')

if [ ! -z "${LDISK}" ];then
  echo "${CURL} ${PROXY}/agent/hostldisk -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"ldisk=${LDISK}\""
  ${CURL} ${PROXY}/agent/hostldisk -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "ldisk=${LDISK}"
  echo -e "\n\n"
fi

#配置详情，系统信息
SYSTEM=$(echo "${product_vendor}||${product_serial}||${product_name}")

if [ ! -z "${SYSTEM}" ];then
  echo "${CURL} ${PROXY}/agent/hostsystem -d \"id=${HOST_ID}&ak=${HOST_AK}\" --data-urlencode \"system=${SYSTEM}\""
  ${CURL} ${PROXY}/agent/hostsystem -d "id=${HOST_ID}&ak=${HOST_AK}" --data-urlencode "system=${SYSTEM}"
  echo -e "\n\n"
fi


