
作业名称：
安装mysqld_exporter_linux


官网地址：
https://github.com/prometheus/mysqld_exporter/releases/


创建用户：
添加数据库监控用户，your_password是你的数据库连接密码
CREATE USER `exporter`@`%` IDENTIFIED BY 'your_password';
GRANT Process, Replication Client, Select ON *.* TO `exporter`@`%`;
flush privileges;


剧本附件：
1：mysqld_exporter-0.12.1.linux-amd64.tar
2：mysql_exporter.init
3：mysqld_exporter.server
4：mysqld_exporter.sh


主机变量
host=""
user=""
password=""
cnf="3306.cnf"


剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 上传文件到远程
      copy: src={{ item }} dest=/opt/exporter/
      with_fileglob:
        - "{{ job_path }}/*"

    - name: 安装    
      shell: /bin/bash /opt/exporter/mysqld_exporter.sh "{{ host }}" "{{ user }}" "{{ password }}" "{{ cnf }}"

