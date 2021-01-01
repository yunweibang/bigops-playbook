作业名称：
安装redis_exporter_linux

系统类型：
Linux

剧本附件
1：redis_exporter-v1.15.0.linux-amd64.tar.gz
2：redis_exporter.service
3：redis_exporter.init
4：daemonize-1.7.3-7.el6.x86_64.rpm
5：install.sh

官网下载地址，供参考：
https://github.com/oliver006/redis_exporter


主机变量
redis_addr="localhost:6379"
redis_password=""

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
      shell: mkdir -p {{ dest_path }}/redis_exporter/ 2>/dev/null
      ignore_errors: yes

    - name: 授权安装目录
      shell: sudo chmod 777 /opt {{ dest_path }} 2>/dev/null
      ignore_errors: yes
      
    - name: 上传文件到远程目录
      copy: src={{ item }} dest={{ dest_path }}
      with_fileglob:
        - "{{ job_path }}/*"
    
    - name: 安装    
      shell: /bin/sh {{ dest_path }}/install.sh {{ redis_addr }} {{ redis_password }}
 
      


  

  


  


  

