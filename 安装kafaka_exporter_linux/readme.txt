
作业名称：
安装kafka_exporter_linux

剧本附件
1：kafka_exporter-1.2.0.linux-amd64.tar.gz
2：kafka_exporter.service
3：kafka_exporter.init
4：kafka_exporter.sh

剧本内容
---
- hosts: all
  gather_facts: no

  tasks:      
    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/opt/exporter/
      with_fileglob:
        - "{{ job_path }}/*"
    
    - name: 安装    
      shell: /bin/bash /opt/exporter/kafka_exporter.sh
 
      


  

  


  


  

