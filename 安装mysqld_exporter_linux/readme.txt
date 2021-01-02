作业名称：
安装mysqld_exporter_linux


添加数据库监控用户，your_password是你的数据库连接密码
CREATE USER `exporter`@`%` IDENTIFIED BY 'your_password';
GRANT Process, Replication Client, Select ON *.* TO `exporter`@`%`;
flush privileges;

剧本附件
1：mysqld_exporter-0.12.1.linux-amd64.tar
2：mysql_exporter.init
3：mysqld_exporter.server
4：install.sh

mysqld_exporter-0.12.1.linux-amd64官网下载地址，共参考：
https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz


主机变量
host="xxx.xxx.xxx.xxx"
user="xxx"
password="xxx"
cnf="3306.cnf"

全局变量
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
      shell: mkdir -p {{ dest_path }}/mysqld_exporter 2>/dev/null
      ignore_errors: yes

    - name: 授权安装目录
      shell: sudo chmod 777 /opt {{ dest_path }} 2>/dev/null
      ignore_errors: yes

    - name: 上传文件到远程
      copy: src={{ item }} dest={{ dest_path }}
      with_fileglob:
        - "{{ job_path }}/*"

    - name: 安装    
      shell: /bin/sh {{ dest_path }}/install.sh {{ host }} {{ user }} {{ password }} {{ cnf }}

