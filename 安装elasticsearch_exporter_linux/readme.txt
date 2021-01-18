
作业名称：
安装elasticsearch_exporter_linux


官网地址：
https://github.com/justwatchcom/elasticsearch_exporter/releases


剧本附件：
1：elasticsearch_exporter-1.1.0.linux-amd64.tar.gz
2：elasticsearch_exporter.service
3：elasticsearch_exporter.init
4：elasticsearch_exporter.sh


主机变量：
es_user="elastic"
es_pass=""
es_ip=""
es_port="9200"


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
      shell: /bin/bash /opt/exporter/elasticsearch_exporter.sh {{ es_user }} {{ es_pass }} {{ es_ip }} {{ es_port }}
 
      


  

  


  


  

