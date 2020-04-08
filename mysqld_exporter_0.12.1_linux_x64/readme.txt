安装mysqld_exporter-0.12.1.linux-amd64


添加数据库监控用户，your_password是你的数据库连接密码
CREATE USER `exporter`@`%` IDENTIFIED BY 'your_password';
GRANT Process, Replication Client, Select ON *.* TO `exporter`@`%`;
flush privileges;

剧本附件
1：mysqld_exporter-0.12.1.linux-amd64.tar
下载地址：https://github.com/prometheus/mysqld_exporter/releases/download/v0.12.1/mysqld_exporter-0.12.1.linux-amd64.tar.gz

2：my.cnf、mysql_exporter.init、mysqld_exporter.server
下载地址：当前仓库


变量内容
src_file="/opt/bigops/job/{{ job_id }}/mysqld_exporter-0.12.1.linux-amd64.tar.gz"  #源文件
mycnf_file="/opt/bigops/job/{{ job_id }}/my.cnf"  #源文件
init_file="/opt/bigops/job/{{ job_id }}/mysqld_exporter.init"  #CentOS6开机启动文件
systemctl_file="/opt/bigops/job/{{ job_id }}/mysqld_exporter.service"  #CentOS7开机启动文件
dest_path="/opt/exporter/"  #目标路径
unarchive_dir="mysqld_exporter-0.12.1.linux-amd64"  #解压后的目录


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
      shell: if [ ! -z \"$(ps aux|grep mysqld_exporter|grep -v grep|awk '{print $2}')\" ];then ps aux|grep mysqld_exporter|grep -v grep|awk '{print $2}'|xargs kill -9;fi
      ignore_errors: yes

    - name: 创建安装目录
      shell: mkdir -p {{ dest_path }}/mysqld_exporter
      ignore_errors: yes

    - name: 上传文件到远程
      copy:
        src: '{{ item.src }}'
        dest: '{{ item.dest }}'
      with_items:
        - { src: "{{ src_file }}", dest: "{{ dest_path }}" }
        - { src: "{{ init_file }}", dest: "{{ dest_path }}" }
        - { src: "{{ systemctl_file }}", dest: "{{ dest_path }}" }
        - { src: "{{ mycnf_file }}", dest: "{{ dest_path }}" }
    
    - name: 解压文件    
      shell: tar zxvf {{ dest_path }}/mysqld_exporter-0.12.1.linux-amd64.tar.gz -C /opt/exporter/  
      
    - name: 拷贝文件mysqld_exporter 
      shell: cp -f {{ dest_path }}/{{ unarchive_dir }}/mysqld_exporter {{ dest_path }}/mysqld_exporter/
      
    - name: 拷贝文件my.cnf
      shell: cp -f {{ dest_path }}/my.cnf {{ dest_path }}/mysqld_exporter/
      
    - name: 执行权限
      shell: chmod -R 777 {{ dest_path }}/mysqld_exporter/

    - name: 设置CentOS7开机启动
      shell: mv -f {{ dest_path }}/mysqld_exporter.service /usr/lib/systemd/system/mysqld_exporter.service
      when: ansible_service_mgr == 'systemd'
    
    - name: CentOS7启动
      shell: systemctl enable mysqld_exporter.service && systemctl start mysqld_exporter.service
      when: ansible_service_mgr == 'systemd'
      
    - name: 设置CentOS6开机启动
      shell: mv -f {{ dest_path }}/mysqld_exporter.init /etc/init.d/mysqld_exporter && chmod 777 /etc/init.d/mysqld_exporter
      when: ansible_service_mgr != 'systemd'
      
    - name: CentOS6启动
      shell: chkconfig mysqld_exporter on && service mysqld_exporter start
      when: ansible_service_mgr != 'systemd'
 
    
