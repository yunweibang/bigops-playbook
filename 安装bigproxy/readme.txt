
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


安装剧本内容
---
- hosts: all
  gather_facts: no

  tasks:      
    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/opt/bigops/bigproxy
      with_fileglob:
        - "{{ job_path }}/*"
      
    - name: 运行安装脚本
      shell: /bin/bash /opt/bigops/bigproxy/install.sh

    - name: 检查bigproxy进程
      shell: ps -ef|grep bigproxy|grep -v grep
      register: bigproxy_proc

    - name: 显示进程
      debug: 
        msg: "{{ bigproxy_proc['stdout_lines'] }}"


卸载剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 停止Proxy服务
      shell: sudo systemctl stop bigproxy
      
    - name: 关闭Proxy服务
      shell: sudo systemctl disable bigproxy     

