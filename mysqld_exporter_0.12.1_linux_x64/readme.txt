安装mysqld_exporter-0.12.1.linux-amd64

监控模式说明：安装一个mysqld_exporter监控所有数据库，每个数据库起一个mysqld_exporter端口


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
dest_path="/opt/exporter/"  #目标路径
unarchive_dir="mysqld_exporter-0.12.1.linux-amd64"  #解压后的目录
all_file="/opt/bigops/job/{{ job_id }}/"  #所有文件
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

    - name: 创建安装目录
      shell: if [ ! -d "{{ dest_path }}/mysqld_exporter" ];then mkdir -p "{{ dest_path }}/mysqld_exporter";fi

    - name: 上传所有文件到远程
      shell: scp -r "{{ all_file }}" "{{ dest_path }}"
    
    - name: 解压文件    
      shell: tar zxvf {{ dest_path }}/{{ job_id }}/mysqld_exporter-0.12.1.linux-amd64.tar.gz -C /opt/exporter/  
      
    - name: 拷贝文件mysqld_exporter 
      shell: cp -f {{ dest_path }}/{{unarchive_dir }}/mysqld_exporter {{ dest_path }}/mysqld_exporter/
      
    - name: 拷贝文件my.cnf
      shell: cp -f {{ dest_path }}/{{ job_id }}/*.cnf {{ dest_path }}/mysqld_exporter/
      
    - name: 拷贝启动脚本
      shell: cp -f {{ dest_path }}/{{ job_id }}/mysqld_exporter_start.sh {{ dest_path }}/mysqld_exporter/

    - name: 执行权限
      shell: chmod -R 777 {{ dest_path }}/mysqld_exporter/
      
    - name: 启动程序
      shell: /bin/bash {{ dest_path }}/mysqld_exporter/mysqld_exporter_start.sh
      
        
    
