监控模式
安装一个mysqld_exporter监控所有数据库，每个数据库起一个mysqld_exporter端口


添加数据库监控用户，your_password是你的数据库连接密码
CREATE USER `exporter`@`%` IDENTIFIED BY 'your_password';
GRANT Process, Replication Client, Select ON *.* TO `exporter`@`%`;
flush privileges;

剧本附件
1：mysqld_exporter-0.12.1.linux-amd64.tar
下载地址：https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz

2：mysqld_exporter_start.sh
下载地址：https://raw.githubusercontent.com/yunweibang/bigops-playbook/master/mysqld_exporter_0.12.1_linux_x64/files/mysqld_exporter_start.sh

3：172.31.173.22.cnf
下载地址：https://raw.githubusercontent.com/yunweibang/bigops-playbook/master/mysqld_exporter_0.12.1_linux_x64/files/172.31.173.22.cnf
修改文件名和内容为你的数据库连接信息

变量内容
src_file="/opt/bigops/job/{{ job_id }}/mysqld_exporter-0.12.1.linux-amd64.tar.gz"  #源文件
dest_path="/opt/exporter"  #目标路径
unarchive_dir="mysqld_exporter-0.12.1.linux-amd64"  #解压后的目录
my_cnf_file="/opt/bigops/job/{{ job_id }}/my.cnf"  #MySQL连接配置文件
init_file="/opt/bigops/job/{{ job_id }}/mysqld_exporter"  #CentOS6开机启动文件
systemctl_file="/opt/bigops/job/{{ job_id }}/mysqld_exporter.service"  #CentOS7开机启动文件


剧本内容
---
- hosts: all
  gather_facts: true

  tasks:
    - name: Collect only facts returned by facter
      setup:
        gather_subset:
          - '!all'
          - '!any'
          - facter
        
    - name: 关闭服务
      shell: "if [ ! -z \"$(ps aux|grep mysqld_exporter|grep -v grep|awk '{print $2}')\" ];then ps aux|grep mysqld_exporter|grep -v grep|awk '{print $2}'|xargs kill -9;fi"
      ignore_errors: yes
      
    - name: 删除源目录
      file:
        path: "{{ dest_path }}/mysqld_exporter"
        state: absent

    - name: 创建安装目录
      shell: "if [ ! -d {{ dest_path }} ];then mkdir {{ dest_path }};fi"
    
    - name: 解压文件到远程主机
      unarchive: 
        src:  "{{ src_file }}"
        dest: "{{ dest_path }}"
        copy: yes

    - name: 目录改名
      shell: mv -f "{{ dest_path }}/{{ unarchive_dir }}" "{{ dest_path }}/mysqld_exporter" 
      
    - name: 上传my.cnf文件
      copy: 
        src:  "{{ my_cnf_file }}"
        dest: "{{ dest_path }}/mysqld_exporter/"

    - name: 执行权限
      shell: chmod -R 777 "{{ dest_path }}" 

    - name: 拷贝CentOS7开机启动文件
      copy: 
        src:  "{{ systemctl_file }}"
        dest: "/usr/lib/systemd/system/"
      when: ansible_service_mgr == 'systemd'
      
    - name: 应用CentOS7开机启动
      shell: systemctl enable mysqld_exporter
      when: ansible_service_mgr == 'systemd'
    
    - name: CentOS7停止服务
      shell: systemctl stop mysqld_exporter
      when: ansible_service_mgr == 'systemd'
      ignore_errors: yes
      
    - name: CentOS7启动服务
      shell: systemctl start mysqld_exporter
      when: ansible_service_mgr == 'systemd'
  
    - name: 拷贝CentOS6开机启动文件
      copy: 
        src:  "{{ init_file }}"
        dest: "/etc/init.d/"
      when: ansible_service_mgr != 'systemd'

    - name: 应用CentOS6开机启动
      shell: chmod 777 /etc/init.d/mysqld_exporter && chkconfig mysqld_exporter on &&  yum -y install daemonize
      when: ansible_service_mgr != 'systemd'
      ignore_errors: yes
    
    - name: CentOS6停止服务
      shell: service mysqld_exporter stop
      when: ansible_service_mgr != 'systemd'
      ignore_errors: yes
      
    - name: CentOS6启动服务
      shell: service mysqld_exporter start
      when: ansible_service_mgr != 'systemd'
