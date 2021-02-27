#!/bin/bash


if [ -d /opt/bigops/jdk ];then
    export JAVA_HOME=/opt/bigops/jdk
    export PATH=$JAVA_HOME/bin:$PATH
    export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
    sed -i 's#securerandom.source=.*#securerandom.source=file:/dev/./urandom#g' /opt/bigops/jdk/jre/lib/security/java.security >/dev/null 2>&1
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

cd /opt/bigops/bigproxy/

/opt/bigops/jdk/bin/java -jar -Duser.timezone=GMT+08 -Djava.net.preferIPv4Stack=true jvm_option /opt/bigops/bigproxy/bigproxy.jar >/dev/null 2>&1 &

