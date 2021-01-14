作业名称：安装系统必备软件

剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 收集信息
      setup:
        gather_subset:
          - min

    - name: 创建/opt/bigops/rpm目录
      shell: if [ ! -d /opt/bigops/rpm ];then sudo mkdir -p /opt/bigops/rpm;fi 

    - name: 授权/opt/bigops/rpm权限
      shell: sudo chmod 777 /opt/bigops/rpm
  
    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/opt/bigops/rpm
      with_fileglob:
        - "{{ job_path }}/*"

    - name: 安装daemonize
      shell: if [ ! -f /usr/sbin/daemonize ];then sudo rpm -ivh /opt/bigops/rpm/daemonize-1.7.3-7.el6.x86_64.rpm;fi
      when: (ansible_distribution == "RedHat" and ansible_distribution_major_version == "6") or
            (ansible_distribution == "CentOS" and ansible_distribution_major_version == "6")
