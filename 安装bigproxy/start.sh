#!/bin/bash


javahome=$(ls -d /usr/lib/jvm/java-1.8.0-openjdk-1.8.0*|grep -v debug|head -n 1)

if [ ! -z "${javahome}" ];then
    export JAVA_HOME=${javahome}
    export PATH=$JAVA_HOME/bin:$PATH
    export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
    sed -i 's#securerandom.source=.*#securerandom.source=file:/dev/./urandom#g' ${javahome}/jre/lib/security/java.security >/dev/null 2>&1
else
    echo "没发现JAVA_HOME，退出!"
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

if [ ! -d /opt/bigops/bigproxy/temp ];then
    mkdir -p /opt/bigops/bigproxy/temp
fi

if [ ! -d /opt/bigops/bigproxy/hostmon_temp ];then
    mkdir -p /opt/bigops/bigproxy/hostmon_temp
fi

cd /opt/bigops/bigproxy/

java -jar -Duser.timezone=GMT+08 -Djava.net.preferIPv4Stack=true -Xms4G -Xmx4G /opt/bigops/bigproxy/bigproxy.jar >/dev/null 2>&1 &

