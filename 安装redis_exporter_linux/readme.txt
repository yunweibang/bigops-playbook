
作业名称：
安装redis_exporter_linux


官网地址：
https://github.com/oliver006/redis_exporter


剧本附件：
1：redis_exporter-v1.15.0.linux-amd64.tar.gz
2：redis_exporter.service
3：redis_exporter.init
4：redis_exporter.sh


主机变量：
redis_addr="localhost:9121"
redis_pass=""


剧本内容：
---
- hosts: all
  gather_facts: no

  tasks:      
    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/opt/exporter/
      with_fileglob:
        - "{{ job_path }}/*"
    
    - name: 安装    
      shell: /bin/bash /opt/exporter/redis_exporter.sh {{ redis_addr }} {{ redis_pass }}
 
      


  

  


  


  

