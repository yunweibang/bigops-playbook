#!/bin/bash

source /opt/bigops/bigagent/bigagent.conf

nodename=$(uname -n)
cpu_count=$(grep -i '^physical id' /proc/cpuinfo|sort|uniq|wc -l)
cpu_cores=$(grep -i '^core id' /proc/cpuinfo|sort|uniq|wc -l)
vcpus=$(grep -i '^processor' /proc/cpuinfo|sort|uniq|wc -l)
mem_total=$(free -k|grep -i mem|awk '{print $2/1024}')
disk_total=$(df -k|grep '^/'|awk 'NF>1{print $2}'|awk -v total=0 '{total+=$1}END{print total/1024}')
virt_type=$(timeout 5 sudo virt-what)
architecture=$(arch)
kernel=$(uname -r)
distribution=$(lsb_release -a|grep 'Distributor ID'|awk '{print $NF}')
distribution_version=$(lsb_release -a|grep 'Release'|awk '{print $NF}'|awk -F. '{print $1"."$2}')
distribution_major_version=$(echo ${distribution_version}|awk -F. '{print $1}')
lan_ip=$(/usr/sbin/ip a|grep 'inet.*brd'|grep -Ev '(veth|docker|tap|virbr)'|awk '{print $2}'|awk -F/ '{print $1}'|grep -E '^(192|172|10|18)\.'|uniq|sort)
wan_ip=$(/usr/sbin/ip a|grep 'inet.*brd'|grep -Ev '(veth|docker|tap|virbr)'|awk '{print $2}'|awk -F/ '{print $1}'|grep -Ev '^(192|172|10|18|[a-z]|:)'|uniq|sort)
product_vendor=$(timeout 5 sudo dmidecode -s system-manufacturer|sed 's#[A-Z]#\l&#g'|sed 's/ .*//g')
product_name=$(timeout 5 sudo dmidecode -s system-product-name)
product_serial=$(timeout 5 sudo dmidecode -s system-serial-number)

HEIGHT=$(timeout 5 sudo dmidecode -s system-product-name)
if [ ! -z "$(echo "${HEIGHT}"|grep -E 'PowerEdge (18|19|R41|R61)')" ];then
  height=1
fi

if [ ! -z "$(echo "${HEIGHT}"|grep -E 'PowerEdge (28|29|R71|R72|R73)')" ];then
  height=2
fi

if [ ! -z "${height}" ];then
HOSTINFO="{
\"nodename\": \"${nodename}\",
\"cpu_count\": ${cpu_count},
\"cpu_cores\": ${cpu_cores},
\"vcpus\": ${vcpus},
\"mem_total\": ${mem_total},
\"disk_total\": ${disk_total},
\"virt_type\": \"${virt_type}\",
\"architecture\": \"${architecture}\",
\"kernel\": \"${kernel}\",
\"distribution\": \"${distribution}\",
\"distribution_major_version\": \"${distribution_major_version}\",
\"distribution_version\": \"${distribution_version}\",
\"lan_ip\": \"${lan_ip}\",
\"wan_ip\": \"${wan_ip}\",
\"height\": ${height},
\"product_vendor\": \"${product_vendor}\",
\"product_vendor\": \"${product_vendor}\",
\"product_name\": \"${product_name}\",
\"product_serial\": \"${product_serial}\"
}"
else
HOSTINFO="{
\"nodename\": \"${nodename}\",
\"cpu_count\": ${cpu_count},
\"cpu_cores\": ${cpu_cores},
\"vcpus\": ${vcpus},
\"mem_total\": ${mem_total},
\"disk_total\": ${disk_total},
\"virt_type\": \"${virt_type}\",
\"architecture\": \"${architecture}\",
\"kernel\": \"${kernel}\",
\"distribution\": \"${distribution}\",
\"distribution_major_version\": \"${distribution_major_version}\",
\"distribution_version\": \"${distribution_version}\",
\"lan_ip\": \"${lan_ip}\",
\"wan_ip\": \"${wan_ip}\",
\"product_vendor\": \"${product_vendor}\",
\"product_vendor\": \"${product_vendor}\",
\"product_name\": \"${product_name}\",
\"product_serial\": \"${product_serial}\"
}"
fi


# echo "${HOSTINFO}"

if [ ! -z "${HOSTINFO}" ];then
  ${CURL} ${proxy}/agent/hostinfo -d "id=${host_id}&ak=${host_ak}" --data-urlencode "hostinfo=${HOSTINFO}"
  echo -e "\n\n"
fi

#配置详情，NIC，格式：name||mac||speed||status
NIC=$(ls /sys/class/net|grep -Ev '^(lo|v)'|while read i
do
  STATUS=$(ethtool ${i}|grep detected|awk '{print $NF}')
  if [ "${STATUS}" == 'no' ];then
     echo "${i}|| || || || || ||DOWN"
  fi
  if [ "${STATUS}" == 'yes' ];then
    MAC=$(cat /sys/class/net/${i}/address)
    SPEED=$(cat /sys/class/net/${i}/speed 2>/dev/null)
    if [ $? == 0 ];then
      SPEED="${SPEED}Mb/s"
    fi
    echo "${i}||${MAC:= }||${SPEED:= }||UP"
  fi
done)

if [ ! -z "{NIC}" ];then
  ${CURL} ${proxy}/agent/hostnic -d "id=${host_id}&ak=${host_ak}" --data-urlencode "nic=${NIC}"
  echo -e "\n\n"
fi


if [ -z "$(timeout 5 sudo virt-what)" ];then

  #厂商型号
  if [[ ! -z "${product_vendor}" ]] && [[ ! -z "${product_name}" ]] && [[ -z "${virt_type}" ]];then
    ${CURL} ${proxy}/agent/hwmodel -d "id=${host_id}&ak=${host_ak}&vendor=${product_vendor}&model=${product_name}"
    echo -e "\n\n"
  fi

  #ipmi
  if hash ipmitool 2>/dev/null; then
    ipmi=$(timeout 5 sudo ipmitool mc info 2>/dev/null)
    if [ ! -z "${ipmi}" ];then
      ipmi_lan=$(timeout 5 sudo ipmitool lan print 1)
      ipmi_ip=$(echo "${ipmi_lan}"|grep -E 'IP Address'|awk '{print $NF}'|grep -E ^[0-9])
      ${CURL} ${proxy}/agent/hostipmi -d "id=${host_id}&ak=${host_ak}&ip=${ipmi_ip}"
      echo -e "\n\n"
    fi
  fi

#配置详情，内存信息
MEM=$(timeout 5 sudo dmidecode -t 17 |awk '/Memory Device/,0'|awk -F":[ ]" '\
{if ($1 ~ /^\tSize$/) printf("%s||",$2)};\
{if ($1 ~ /^\tLocator$/) printf("%s||",$2)};\
{if ($1 ~ /^\tType$/) printf("%s||",$2)};\
{if ($1 ~ /^\tSpeed$/) printf("%s||",$2)};\
{if ($1 ~ /^\tManufacturer$/) printf("%s||",$2)};\
{if ($1 ~ /^\tSerial Number$/) printf("%s||",$2)};\
{if ($1 ~ /^\tPart Number$/) printf("%s\n",$2)};' \
|grep -E '^[0-9]'|sed 's/[ ]*||/||/g' \
|awk -F'[|][|]' '{if($7 == "") {print $0,"|| ||"} else{print $0}}')

  #echo "${MEM}"

  if [ ! -z "${MEM}" ];then
  	${CURL} ${proxy}/agent/hostmem -d "id=${host_id}&ak=${host_ak}" --data-urlencode "mem=${MEM}"
    echo -e "\n\n"
  fi

#配置详情，CPU统计 
  PCPU=$(cat /proc/cpuinfo|grep -E 'physical id'|sort|uniq|wc -l)
  if hash lscpu 2>/dev/null; then
    LCPU=$(lscpu|grep -E '^CPU\(s\)'|awk '{print $NF}')
    if [ "$(lscpu|grep -E '^Thread'|awk '{print $NF}'|head -n 1)" == 2 ];then
       HT="启用"
    fi
    if [ "$(lscpu|grep -E '^Thread'|awk '{print $NF}'|head -n 1)" == 1 ];then
       HT="禁用"
    fi
    SPEED=$(lscpu|grep -E '^CPU MHz'|awk '{print $NF}')
  fi

  CPUSTATS=$(echo "${PCPU}||${LCPU:= }||${HT:=not found lscpu}||${SPEED:= }")

  if [ ! -z "${CPUSTATS}" ];then
    ${CURL} ${proxy}/agent/hostcpustats -d "id=${host_id}&ak=${host_ak}" --data-urlencode "cpustats=${CPUSTATS}"
    echo -e "\n\n"
  fi

  if [ ! -z "${CPU}" ];then
    ${CURL} ${proxy}/agent/hostcpu -d "id=${host_id}&ak=${host_ak}" --data-urlencode "cpu=${CPU}"
    echo -e "\n\n"
  fi

#配置详情，CPU，格式：socket||model||core_count||ht

CPU=$(timeout 5 sudo dmidecode -t processor | awk -F":[ ]" '\
{if ($1 ~ /^\tSocket Designation$/) printf("%s||",$2)};\
{if ($1 ~ /^\tVersion$/) printf("%s||",$2)};\
{if ($1 ~ /^\tCore Count$/) printf("%s\n",$2)};' \
|sed 's/[ ][ ]*/ /g'|awk '{print $0"||""'${HT}'"}')

  #列子："CPU1||Intel(R) Xeon(R) CPU E5310 @ 1.60GHz||core count||HT" 
  ${CURL} ${proxy}/agent/hostcpu -d "id=${host_id}&ak=${host_ak}" --data-urlencode "cpu=${CPU}"
  echo -e "\n\n"

fi


#配置详情，磁盘分区
DISKPART=$(df -h|grep -E ^/|awk '{print $1"||"$2"||"$3"||"$4"||"$5"||"$6}'|sed 's/[ ][ ]*/||/g'|sed 's/%//g')

if [ ! -z "${DISKPART}" ];then
	${CURL} ${proxy}/agent/hostdiskpart -d "id=${host_id}&ak=${host_ak}" --data-urlencode "diskpart=${DISKPART}"
  echo -e "\n\n"
fi


#配置详情，虚拟盘
LDISK=$(timeout 5 sudo fdisk -l|grep '/dev'|grep -E '(bytes|字节)'|awk -F'：|:' '{print $1,$2}'|awk '{print $2"||"$3,$4}'|sed 's/,$//')

if [[ $? == 0 ]] && [[ ! -z "${LDISK}" ]];then
	${CURL} ${proxy}/agent/hostldisk -d "id=${host_id}&ak=${host_ak}" --data-urlencode "ldisk=${LDISK}"
  echo -e "\n\n"
fi


#配置详情，物理盘，格式：model||sn||size||rr||inch||interface||speed
if [[ ! -z "${LDISK}" ]] && [[ -z "$(timeout 5 sudo virt-what)" ]];then
  ALL_PDISK=$(echo "${LDISK}"|awk -F'[|][|]' '{print $1}'|grep -Ev '/dev/mapper'|while read ldisk
  do
    PDISK=$(timeout 5 sudo smartctl -a "${ldisk}")
    if [ ! -z "$(echo "${PDISK}"|grep -E 'User Capacity')" ];then
      VENDOR=$(echo "${PDISK}"|awk -F: '/^Vendor/{print $2}'|sed 's/^[ ]*//g')
      PRODUCT=$(echo "${PDISK}"|awk -F: '/^Product/{print $2}'|sed 's/^[ ]*//g')
      MODEL=$(echo "${PDISK}"|awk -F: '/Model:/{print $2}'|sed 's/^[ ]*//g')
      if [ -z "${MODEL}" ];then
        MODEL="${VENDOR} ${PRODUCT}"
      fi
      SN=$(echo "${PDISK}"|awk -F: '/^Serial/{print $2}'|sed 's/^[ ]*//g')
      SIZE=$(echo "${PDISK}"|awk -F: '/^User Capacity/{print $2}'|sed 's/^[ ]*//g'|awk -F'bytes ' '{print $2}'|sed 's/\[//g'|sed 's/\]//g')
      RR=$(echo "${PDISK}"|awk -F: '/^Rotation/{print $2}'|sed 's/^[ ]*//g')
      INCH=$(echo "${PDISK}"|awk -F: '/^Form Factor:/{print $2}'|sed 's/^[ ]*//g')
      INTERFACE=$(echo "${PDISK}"|grep '(current: '|awk -F: '{print $2}'|awk -F'\\(current' '{print $1}'|sed 's/^[ ]*//g')
      SPEED=$(echo "${PDISK}"|grep '(current: '|awk '{print $(NF-1),$NF}'|sed 's/)//g')
      echo "${MODEL:= }||${SN:= }||${SIZE:= }||${RR:= }||${INCH:= }||${INTERFACE:= }||${SPEED:= }||"
    fi
  done)

  #echo "${ALL_PDISK}"
  if [ ! -z "${ALL_PDISK}" ];then
     ${CURL} ${proxy}/agent/hostpdisk -d "id=${host_id}&ak=${host_ak}" --data-urlencode "pdisk=${ALL_PDISK}"
     echo -e "\n\n"
  fi
fi

#配置详情，系统信息
if [ -z "$(timeout 5 sudo virt-what)" ];then
  SYSTEM=$(timeout 5 sudo dmidecode -t system|awk -v FS=':' '/^\t(Manufacturer|Product Name|Serial Number):/{$1="";printf("%s||",$0)}/^$/'|sed 's/^[ ]*//g'|sed 's/||[ ]*/||/g'|sed '/^$/d')
  SYSTEM=$(echo "${SYSTEM}"|awk -F'[|][|]' '{print $1"||"$3"||"$2}')
  if [[ $? == 0 ]] && [[ ! -z "${SYSTEM}" ]];then
    #echo "${CURL} ${proxy}/agent/hostsystem -d \"id=${host_id}&ak=${host_ak}\" --data-urlencode \"system=${SYSTEM}\""
    ${CURL} ${proxy}/agent/hostsystem -d "id=${host_id}&ak=${host_ak}" --data-urlencode "system=${SYSTEM}"
    echo -e "\n\n"
  fi

#配置详情，RAID卡
RAIDADP=$(timeout 5 sudo MegaCli64 -AdpAllInfo -aALL -NoLog |awk '/^Adapter/,/Delay during/' |sed 's/^Adapter/Adapter:/g'| awk -F": |" '\
{if ($1 ~ /^Adapter/) printf("%s||",$2)};\
{if ($1 ~ /^Product Name/) printf("%s||",$2)};\
{if ($1 ~ /^Serial No/) printf("%s||",$2)};\
{if ($1 ~ /^FW Version/) printf("%s||",$2)};\
{if ($1 ~ /^Memory Size/) printf("%s||",$2)};\
{if ($1 ~ /  Degraded/) printf("%s||",$2)};\
{if ($1 ~ /  Offline/) printf("%s||",$2)};\
{if ($1 ~ /  Disks/) printf("%s||",$2)};\
{if ($1 ~ /  Critical Disks/) printf("%s||",$2)};\
{if ($1 ~ /  Failed Disks/) printf("%s\n",$2)};'\
|sed 's/\[.*\]//'g|sed 's/[ ][ ]*/ /g'|sed 's/[ ]*||/||/g')


#echo "${RAIDADP}"

if [ ! -z "${RAIDADP}" ];then
   ${CURL} ${proxy}/agent/hostraidadp -d "id=${host_id}&ak=${host_ak}" --data-urlencode "raidadp=${RAIDADP}"
   echo -e "\n\n"
fi

#配置详情，RAID物理盘
RAIDPD=$(timeout 5 sudo MegaCli64 -PDList -aALL -NoLog | awk -F": " '\
{if ($1 ~ /^Enclosure Device ID/) printf("%s||",$2)};\
{if ($1 ~ /^Slot Number/) printf("%s||",$2)};\
{if ($1 ~ /^Media Error Count/) printf("%s||",$2)};\
{if ($1 ~ /^Other Error Count/) printf("%s||",$2)};\
{if ($1 ~ /^Raw Size/) printf("%s||",$2)};\
{if ($1 ~ /^Firmware state/) printf("%s||",$2)};\
{if ($1 ~ /^Inquiry Data/) printf("%s||",$2)};\
{if ($1 ~ /^Device Speed/) printf("%s||",$2)};\
{if ($1 ~ /^Link Speed/) printf("%s||",$2)};\
{if ($1 ~ /^Media Type/) printf("%s\n",$2)};'\
|sed 's/\[.*\]//'g|sed 's/[ ][ ]*/ /g'|sed 's/[ ]*||/||/g')

RAIDPD=$(echo "${RAIDPD}"|sed 's/Solid State Device/SSD/g')

if [ ! -z "${RAIDPD}" ];then
   ${CURL} ${proxy}/agent/hostraidpd -d "id=${host_id}&ak=${host_ak}" --data-urlencode "raidpd=${RAIDPD}"
   echo -e "\n\n"
fi

#配置详情，RAID虚拟盘
RAIDLD=$(timeout 5 sudo MegaCli64 -LDInfo -Lall -aALL -NoLog |awk '/^Adapter/,/Encryption Type/'|sed 's/^Adapter/Adapter:/g'| awk -F":|--" '\
{if ($1 ~ /^Adapter/) printf("%s||",$2)};\
{if ($1 ~ /^Virtual Disk/) printf("%s||",$2)};\
{if ($1 ~ /^RAID Level/) printf("%s||",$2)};\
{if ($1 ~ /^Size/) printf("%s||",$2)};\
{if ($1 ~ /^State/) printf("%s||",$2)};\
{if ($1 ~ /^Strip/) printf("%s||",$2)};\
{if ($1 ~ /^Current Cache Policy/) printf("%s\n",$2)};'\
|sed 's/\[.*\]//'g|sed 's/[ ][ ]*/ /g'|sed 's/[ ]*||/||/g'|sed 's/^[ ]*//g'|sed 's/|| /||/g'|sed 's/ (Target Id//g')

RAIDLD=$(echo "${RAIDLD}"|sed 's#Primary-1, Secondary-0, RAID Level Qualifier-0#RAID1#g')
RAIDLD=$(echo "${RAIDLD}"|sed 's#Primary-0, Secondary-0, RAID Level Qualifier-0#RAID1#g')
RAIDLD=$(echo "${RAIDLD}"|sed 's#Primary-5, Secondary-0, RAID Level Qualifier-3#RAID5#g')
RAIDLD=$(echo "${RAIDLD}"|sed 's#Primary-1, Secondary-3, RAID Level Qualifier-0#RAID10#g')

if [ ! -z "${RAIDLD}" ];then
   ${CURL} ${proxy}/agent/hostraidld -d "id=${host_id}&ak=${host_ak}" --data-urlencode "raidld=${RAIDLD}"
   echo -e "\n\n"
fi

fi




