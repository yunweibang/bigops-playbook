剧本附件
1、zabbix_agentd、zabbix_get、zabbix_sender、zabbix_agentd.conf

附件生成方法：
源代码下载，地址：https://www.zabbix.com/download
静态编译：
yum -y install glibc-static libcurl-devel pcre*
./configure --prefix=/usr --sysconfdir=/etc/zabbix --enable-agent --enable-static 

把zabbix_agentd、zabbix_get、zabbix_sender、zabbix_agentd.conf拷贝到笔记本上传到剧本附件



变量内容
src_file="/opt/bigops/job/{{ job_id }}/zabbix_agent-4.4.6-linux-x86_64.zip" #安装文件
unzip_dir="zabbix_agent-4.4.6-linux-x86_64"  #解压目录
ServerActive="172.31.173.22"


剧本内容
---
- hosts: all
  gather_facts: no
  
  tasks:
  - name: 启动zabbix_agent服务
    service:
      name: zabbix-agent
      state: stopped
    ignore_errors: yes
      
  - name: 解压本地文件到远程主机
    unarchive: 
      src:  "{{ src_file }}"
      dest: /tmp
      copy: yes

  - name: 更新zabbix_get文件
    shell: mv -f /tmp/{{ unzip_dir }}/zabbix_get /usr/bin/

  - name: 更新zabbix_sender文件
    shell: mv -f /tmp/{{ unzip_dir }}/zabbix_sender /usr/bin/

  - name: 更新zabbix_agentd文件
    shell: mv -f /tmp/{{ unzip_dir }}/zabbix_agentd /usr/sbin/

  - name: 给zabbix_agentd文件执行权限
    shell: chmod 777 /usr/sbin/zabbix_agentd

  - name: 更新zabbix_agentd.conf文件
    shell: mv -f /tmp/{{ unzip_dir }}/zabbix_agentd.conf /etc/zabbix/
    
  - name: 更新Hostname配置
    lineinfile:
      path: /etc/zabbix/zabbix_agentd.conf
      regexp: '^Hostname='
      line: 'Hostname={{ inventory_hostname }}'
      backrefs: no
      
  - name: 更新ServerActive配置
    lineinfile:
      path: /etc/zabbix/zabbix_agentd.conf
      regexp: '^ServerActive='
      line: 'ServerActive={{ ServerActive }}'
      backrefs: no

  - name: 启动zabbix_agent服务
    service:
      name: zabbix-agent
      state: started

