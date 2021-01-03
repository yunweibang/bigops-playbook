
作业名称：
安装jmx_exporter


下载jmx_prometheus_javaagent-0.3.1.jar
cd /opt/exporter/
wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.3.1/jmx_prometheus_javaagent-0.3.1.jar


tomcat.yml参考地址
https://github.com/chanjarster/prometheus-learn/blob/master/jvm-monitoring/jmx-exporter-config.yml

/opt/exporter/tomcat.yml内容如下:
---
lowercaseOutputLabelNames: true
lowercaseOutputName: true
whitelistObjectNames: ["java.lang:type=OperatingSystem"]
rules:
 - pattern: 'java.lang<type=OperatingSystem><>((?!process_cpu_time)w+):'
   name: os_$1
   type: GAUGE
   attrNameSnakeCase: true

vim bin/catalina.sh

CATALINA_OPTS="-Xms64m -Xmx2048m -javaagent:/opt/exporter/jmx_exporter/jmx_prometheus_javaagent-0.3.1.jar=9090:/opt/exporter/tomcat.yml"

9090是代理端口

重启tomcat

查看metrics
192.168.xxx.xxx:9090/metrics