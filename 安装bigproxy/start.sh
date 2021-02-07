#!/bin/bash


if [ -d /opt/bigops/jdk ];then
    export JAVA_HOME=/opt/bigops/jdk
    export PATH=$JAVA_HOME/bin:$PATH
    export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
else
    echo "没发现/opt/bigops/jdk目录，请下载运行初始化环境脚本，退出!"
    exit
fi

if [ ! -f /opt/bigops/bigproxy/config/bigproxy.properties ];then
    echo "没发现/opt/bigops/bigproxy/config/bigproxy.properties，退出!"
    exit
fi

if [ ! -f /opt/bigops/bigproxy/config/whitelist ];then
    echo "没发现/opt/bigops/bigproxy/config/whitelist，退出!"
    exit
fi

if [ ! -d /opt/bigops/bigproxy/hosts ];then
    mkdir -p /opt/bigops/bigproxy/hosts
fi

if [ ! -d /opt/bigops/bigproxy/temp ];then
    mkdir -p /opt/bigops/bigproxy/temp
fi

if [ ! -d /opt/bigops/bigproxy/hostmon_temp ];then
    mkdir -p /opt/bigops/bigproxy/hostmon_temp
fi

sed -i 's#securerandom.source=.*#securerandom.source=file:/dev/./urandom#g' /opt/bigops/jdk/jre/lib/security/java.security >/dev/null 2>&1

cd /opt/bigops/bigproxy/

/opt/bigops/jdk/bin/java -jar -Duser.timezone=GMT+08 -Djava.net.preferIPv4Stack=true -Xms4G -Xmx4G /opt/bigops/bigproxy/bigproxy.jar >/dev/null 2>&1 &

