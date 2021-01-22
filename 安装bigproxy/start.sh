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

cd /opt/bigops/bigproxy/

java -jar -Duser.timezone=GMT+08 -Djava.net.preferIPv4Stack=true -Xms2G -Xmx2G /opt/bigops/bigproxy/bigproxy.jar >/dev/null 2>&1 &

