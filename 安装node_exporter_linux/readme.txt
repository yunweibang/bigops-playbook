作业名称：
安装node_exporter-0.18.1.linux-amd64

系统类型：
Linux

剧本附件
1：node_exporter-0.18.1.linux-amd64.tar.gz
2：syskey.sh
3：userkey.sh
4：node_exporter.service
5：node_exporter.init
6：daemonize-1.7.3-7.el6.x86_64.rpm
7：install.sh

node_exporter-0.18.1.linux-amd64官网下载地址，供参考：
https://github.com/prometheus/node_exporter/


变量内容
dest_path="/opt/exporter/"


剧本内容
---
- hosts: all
  gather_facts: true

  tasks:
    - name: 收集信息
      setup:
        gather_subset:
          - min

    - name: 创建安装目录
      shell: mkdir -p {{ dest_path }}/node_exporter/key/ 2>/dev/null
      ignore_errors: yes

    - name: 授权安装目录
      shell: sudo chmod 777 /opt {{ dest_path }} 2>/dev/null
      ignore_errors: yes
      
    - name: 上传文件到远程目录
      copy: src={{ item }} dest={{ dest_path }}
      with_fileglob:
        - "{{ job_path }}/*"
    
    - name: 安装    
      shell: /bin/sh {{ dest_path }}/install.sh
      
    - name: 添加cron
      cron: name='node_exporter' minute=*/1 job='timeout 30 /bin/bash {{ dest_path }}/node_exporter/key/*key.sh >/dev/null 2>&1'
  

  

  


  


  

