
作业名称：
安装bigproxy


剧本附件：
1：start.sh
2：stop.sh
3：install.sh
4：hostmon.sh
5：hostinfo.sh
6：hostinfo_windows.sh
7：bigproxy.service


剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 创建/opt/bigops/bigproxy/config目录
      shell: if [ ! -d /opt/bigops/bigproxy/config ];then mkdir -p /opt/bigops/bigproxy/config;fi
      
    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/opt/bigops/bigproxy
      with_fileglob:
        - "{{ job_path }}/*"
      
    - name: 运行安装脚本
      shell: /bin/bash /opt/bigops/bigproxy/install.sh


卸载bigproxy
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 停止服务
      shell: sudo systemctl stop bigproxy
      
    - name: 关闭服务
      shell: sudo systemctl disable bigproxy     

