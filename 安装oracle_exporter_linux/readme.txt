
作业名称：
安装oracle_exporter_linux


官网地址：
https://github.com/iamseth/oracledb_exporter/releases


剧本附件：
1：oracledb_exporter.0.2.9-ora18.5.linux-amd64.tar.gz
2：oracle_exporter.service
3：oracle_exporter.init
4：oracle_exporter.sh


主机变量或模板变量：
USER=""
PASS=""
HOST=""
PORT="1521"
SERVICE_NAME=""


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
      shell: /bin/bash /opt/exporter/oracle_exporter.sh {{ USER }} {{ PASS }} {{ HOST }} {{ PORT }} {{ SERVICE_NAME }}

  

  


  


  

