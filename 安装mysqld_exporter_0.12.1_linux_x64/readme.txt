作业名称：
安装mysqld_exporter-0.12.1.linux-amd64

系统类型：
Linux

添加数据库监控用户，your_password是你的数据库连接密码
CREATE USER `exporter`@`%` IDENTIFIED BY 'your_password';
GRANT Process, Replication Client, Select ON *.* TO `exporter`@`%`;
flush privileges;

剧本附件
1：mysqld_exporter-0.12.1.linux-amd64.tar
2：3306.cnf
3：mysql_exporter.init
4：mysqld_exporter.server

mysqld_exporter-0.12.1.linux-amd64官网下载地址，共参考：
https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz


变量内容
dest_path="/opt/exporter/"  #目标安装路径
unarchive_file="mysqld_exporter-0.12.1.linux-amd64.tar.gz"  #压缩文件
unzip_dir="mysqld_exporter-0.12.1.linux-amd64"   #解压目录
my3306="3306.cnf"  #数据库配置文件


剧本内容
---
- hosts: all
  gather_facts: true

  tasks:
    - name: 收集信息
      setup:
        gather_subset:
          - min
        
    - name: 关闭服务
      shell: if [ ! -z "$(ps aux|grep mysqld_exporter|grep -v grep|awk '{print $2}')" ];then ps aux|grep mysqld_exporter|grep -v grep|awk '{print $2}'|xargs kill -9;fi
      ignore_errors: yes

    - name: 创建安装目录
      shell: mkdir -p {{ dest_path }}/mysqld_exporter
      ignore_errors: yes

    - name: 上传文件到远程
      copy: src={{ item }} dest={{ dest_path }}
      with_fileglob:
        - "{{ job_path }}/*"
    
    - name: 解压文件    
      shell: tar zxvf {{ dest_path }}/{{ unarchive_file }} -C {{ dest_path }}
    
    - name: 拷贝文件mysqld_exporter 
      shell: cp -f {{ dest_path }}/{{ unzip_dir }}/mysqld_exporter {{ dest_path }}/mysqld_exporter/

    - name: 设置执行权限
      shell: chmod -R 777 {{ dest_path }}
      
    - name: 拷贝文件3306.cnf
      shell: cp -f {{ dest_path }}/{{ my3306 }} {{ dest_path }}/mysqld_exporter/

    - name: 设置CentOS6开机启动
      shell: mv -f {{ dest_path }}/mysqld_exporter.init /etc/init.d/mysqld_exporter && chmod 777 /etc/init.d/mysqld_exporter
      when: ansible_service_mgr != 'systemd'
      
    - name: CentOS6启动服务
      shell: chkconfig mysqld_exporter on && service mysqld_exporter start
      when: ansible_service_mgr != 'systemd'
      
    - name: 设置CentOS7开机启动
      shell: mv -f {{ dest_path }}/mysqld_exporter.service /usr/lib/systemd/system/mysqld_exporter.service
      when: ansible_service_mgr == 'systemd'

    - name: CentOS7启动服务
      shell: systemctl enable mysqld_exporter.service && systemctl start mysqld_exporter.service
      when: ansible_service_mgr == 'systemd'
      

 