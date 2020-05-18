作业名称：
安装node_exporter-0.18.1.linux-amd64

系统类型：
Linux

剧本附件
1：node_exporter-0.18.1.linux-amd64.tar.gz
2：syskey.sh
3：userkey.sh
4：node_exporter.service
5：node_exporter

node_exporter-0.18.1.linux-amd64官网下载地址，供参考：
https://github.com/prometheus/node_exporter/


变量内容
dest_path="/opt/exporter/"  #目标安装路径
unarchive_file="node_exporter-0.18.1.linux-amd64.tar.gz"  #压缩文件
unzip_dir="{{ unarchive_file | splitext | first | splitext | first }}"   #解压目录


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
      shell: ps aux|grep node_exporter|grep -v grep|awk '{print $2}'|xargs kill -9 2>/dev/null
      ignore_errors: yes

    - name: 创建安装目录
      shell: mkdir -p {{ dest_path }}/node_exporter/key/ 2>/dev/null
      ignore_errors: yes

    - name: 上传文件到远程
      copy: src={{ item }} dest={{ dest_path }}
      with_fileglob:
        - "{{ job_path }}/*"
    
    - name: 解压文件    
      shell: tar zxvf {{ dest_path }}/{{ unarchive_file }} -C {{ dest_path }}
      
    - name: 拷贝node_exporter
      shell: cp -f {{ dest_path }}/{{ unzip_dir }}/node_exporter {{ dest_path }}/node_exporter/
      
    - name: 拷贝key
      shell: mv -f {{ dest_path }}/{{ item }} {{ dest_path }}/node_exporter/key/
      with_items:
        - "syskey.sh"
        - "userkey.sh"

    - name: 设置执行权限
      shell: chmod -R 777 {{ dest_path }}    
      
    - name: 添加cron
      cron: name='node_exporter' minute=*/1 job='timeout 30 /bin/bash {{ dest_path }}/node_exporter/key/*key.sh >/dev/null 2>&1'
  
    - name: 运行key脚本
      shell: "timeout 30 /bin/bash {{ dest_path }}/node_exporter/key/*key.sh"

    - name: 设置CentOS6开机启动
      shell: |
        mv -f {{ dest_path }}/node_exporter.init /etc/init.d/node_exporter 
        chmod 777 /etc/init.d/node_exporter
      when: ansible_service_mgr != 'systemd'

    - name: CentOS6启动服务
      shell: |
        yum -y install daemonize 
        chkconfig node_exporter on
        service node_exporter start
      when: ansible_service_mgr != 'systemd'
      ignore_errors: yes
      
    - name: 设置CentOS7开机启动
      shell: mv -f {{ dest_path }}/node_exporter.service /usr/lib/systemd/system/
      when: ansible_service_mgr == 'systemd'
      
    - name: CentOS7启动服务
      shell: |
        systemctl enable node_exporter
        systemctl start node_exporter
      when: ansible_service_mgr == 'systemd'
  


  

