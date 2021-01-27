
作业名称：
安装rabbitmq_exporter_linux


官网地址：
https://github.com/kbudde/rabbitmq_exporter/releases/


剧本附件：
1：rabbitmq_exporter-1.0.0-RC7.linux-arm64.tar.gz
2：rabbitmq_exporter.service
3：rabbitmq_exporter.init
4：rabbitmq_exporter.sh


主机变量或模板变量：
RABBIT_USER="guest"
RABBIT_PASSWORD="guest"
OUTPUT_FORMAT="JSON"
PUBLISH_PORT="9419"
RABBIT_URL="http://localhost:15672"


剧本内容：
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 创建exporter目录
      shell: if [ ! -d /opt/exporter ];then sudo mkdir -p /opt/exporter;fi 

    - name: 授权exporter权限
      shell: sudo chown bigops:bigops /opt/exporter

    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/opt/exporter
      with_fileglob:
        - "{{ job_path }}/*"

    - name: 安装    
      shell: /bin/bash /opt/exporter/rabbitmq_exporter.sh "{{ RABBIT_USER }}" "{{ RABBIT_PASSWORD }}" "{{ OUTPUT_FORMAT }}" "{{ PUBLISH_PORT }}" "{{ RABBIT_URL }}"

  

  

测试：
curl http://IP:9419/metrics|grep rabbitmq_up
  


  

