剧本附件
1、node_exporter-0.18.1.linux-amd64.tar.gz
下载地址：https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz

变量内容
src_file="/opt/bigops/job/{{ job_id }}/node_exporter-0.18.1.linux-amd64.tar.gz"  #源文件
syskey_file="/opt/bigops/job/{{ job_id }}/syskey.sh"  #系统内置key
userkey_file="/opt/bigops/job/{{ job_id }}/userkey.sh"  #用户自定义key
dest_path="/opt/exporter"  #目标路径
unarchive_dir="node_exporter-0.18.1.linux-amd64"  #解压后的目录
init_file="/opt/bigops/job/{{ job_id }}/node_exporter"  #CentOS6开机启动文件
systemctl_file="/opt/bigops/job/{{ job_id }}/node_exporter.service"  #CentOS7开机启动文件


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
        
    - name: 安装ss
      shell: "if ! hash ss 2>/dev/null;then yum -y install iproute;fi"
    
    - name: 安装mpstat
      shell: "if ! hash mpstat 2>/dev/null;then yum -y install sysstat;fi"
      
    - name: 关闭服务
      shell: "if [ ! -z \"$(ps aux|grep node_exporter|grep -v grep|awk '{print $2}')\" ];then ps aux|grep node_exporter|grep -v grep|awk '{print $2}'|xargs kill -9;fi"
      ignore_errors: yes

    - name: 创建安装目录
      shell: "if [ ! -d {{ dest_path }} ];then mkdir {{ dest_path }};fi"
    
    - name: 解压文件到远程主机
      unarchive: 
        src:  "{{ src_file }}"
        dest: "{{ dest_path }}"
        copy: yes

    - name: 删除源目录
      file:
        path: "{{ dest_path }}/node_exporter"
        state: absent
      
    - name: 目录改名
      shell: mv -f "{{ dest_path }}/{{ unarchive_dir }}" "{{ dest_path }}/node_exporter" 
      
    - name: 创建key目录
      shell: mkdir "{{ dest_path }}/node_exporter/key/" 
    
    - name: 上传系统key
      copy: 
        src:  "{{ syskey_file }}"
        dest: "{{ dest_path }}/node_exporter/key/"

    - name: 上传自定义key
      copy: 
        src:  "{{ userkey_file }}"
        dest: "{{ dest_path }}/node_exporter/key/"
      ignore_errors: yes

    - name: 执行权限
      shell: chmod -R 777 "{{ dest_path }}" 
      
    - name: 添加cron
      cron: name='node_exporter' minute=*/1 job='timeout 30 /bin/bash {{ dest_path }}/node_exporter/key/*key.sh >/dev/null 2>&1'
  
    - name: 运行key脚本
      shell: "timeout 30 /bin/bash {{ dest_path }}/node_exporter/key/*key.sh"

    - name: 拷贝CentOS7开机启动文件
      copy: 
        src:  "{{ systemctl_file }}"
        dest: "/usr/lib/systemd/system/"
      when: ansible_service_mgr == 'systemd'
      
    - name: 应用CentOS7开机启动
      shell: systemctl enable node_exporter
      when: ansible_service_mgr == 'systemd'
    
    - name: CentOS7停止服务
      shell: systemctl stop node_exporter
      when: ansible_service_mgr == 'systemd'
      ignore_errors: yes
      
    - name: CentOS7启动服务
      shell: systemctl start node_exporter
      when: ansible_service_mgr == 'systemd'
  
    - name: 拷贝CentOS6开机启动文件
      copy: 
        src:  "{{ init_file }}"
        dest: "/etc/init.d/"
      when: ansible_service_mgr != 'systemd'

    - name: 应用CentOS6开机启动
      shell: chmod 777 /etc/init.d/node_exporter && chkconfig node_exporter on &&  yum -y install daemonize
      when: ansible_service_mgr != 'systemd'
      ignore_errors: yes
    
    - name: CentOS6停止服务
      shell: service node_exporter stop
      when: ansible_service_mgr != 'systemd'
      ignore_errors: yes
      
    - name: CentOS6启动服务
      shell: service node_exporter start
      when: ansible_service_mgr != 'systemd'
