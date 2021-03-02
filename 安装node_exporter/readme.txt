
作业名称：
安装node exporter


官网地址：
https://github.com/prometheus/node_exporter/


剧本附件：
1：node_exporter-1.1.0.linux-amd64.tar.gz
2：node_exporter.service
3：node_exporter.init
4：node_exporter.sh
5：syskey.sh
6：mpstat



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
      shell: /bin/bash /opt/exporter/node_exporter.sh
      
    - name: 添加cron
      cron: name='node_exporter' minute=*/1 job='timeout 50 /opt/exporter/key/syskey.sh >/dev/null 2>&1'
  

  

  


  


  

