作业名称：
安装zabbix_agent-4.4.6-linux-x86_64

系统类型：
Linux


剧本附件
1：zabbix_agentd
2：zabbix_get
3：zabbix_sender
4：zabbix_agentd.conf

附件生成方法，供参考：
源代码下载，地址：https://www.zabbix.com/download
静态编译：
yum -y install glibc-static libcurl-devel pcre*
./configure --prefix=/usr --sysconfdir=/etc/zabbix --enable-agent --enable-static 

把zabbix_agentd、zabbix_get、zabbix_sender、zabbix_agentd.conf拷贝到笔记本上传到剧本附件


变量内容
dest_path="/etc/zabbix/"  #目标安装路径
Server="172.31.173.22"
ServerActive="172.31.173.22"


剧本内容
---
- hosts: all
  gather_facts: no
  
  tasks:
    - name: 收集信息
      setup:
        gather_subset:
          - min
          
    - name: 关闭服务
      shell: if [ ! -z "$(ps aux|grep zabbix_agentd|grep -v grep|awk '{print $2}')" ];then ps aux|grep zabbix_agentd|grep -v grep|awk '{print $2}'|xargs kill -9;fi
      ignore_errors: yes
    
    - name: 创建安装目录
      shell: mkdir -p {{ dest_path }}
      ignore_errors: yes

    - name: 上传文件到远程
      copy: src={{ item }} dest=/usr/bin/
      with_items:
        - "{{ job_path }}/zabbix_sender"
        - "{{ job_path }}/zabbix_get"    

    - name: 上传文件到远程
      copy: src={{ job_path }}/zabbix_agentd dest=/usr/sbin/

    - name: 上传文件到远程
      copy: src={{ item }} dest={{ dest_path }}
      with_items: 
        - "{{ job_path }}/zabbix_agentd.conf"
        - "{{ job_path }}/zabbix-agent.init"
        - "{{ job_path }}/zabbix-agent.service"

    - name: 设置权限
      shell: chmod 777 /usr/bin/zabbix_sender /usr/bin/zabbix_get /usr/sbin/zabbix_agentd
 
    - name: 更新Hostname配置
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^Hostname='
        line: 'Hostname={{ inventory_hostname }}'
        backrefs: no

    - name: 更新Server配置
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^Server='
        line: 'Server={{ Server }}'
        backrefs: no

    - name: 更新ServerActive配置
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^ServerActive='
        line: 'ServerActive={{ ServerActive }}'
        backrefs: no

    - name: 设置CentOS6开机启动
      shell: mv -f {{ dest_path }}/zabbix-agent.init /etc/init.d/zabbix-agent && chmod 777 /etc/init.d/zabbix-agent
      when: ansible_service_mgr != 'systemd'
      
    - name: CentOS6启动服务
      shell: chkconfig zabbix-agent on && service zabbix-agent start
      when: ansible_service_mgr != 'systemd'
      
    - name: 设置CentOS7开机启动
      shell: mv -f {{ dest_path }}/zabbix-agent.service /usr/lib/systemd/system/zabbix-agent.service
      when: ansible_service_mgr == 'systemd'

    - name: CentOS7启动服务
      shell: systemctl enable zabbix-agent.service && systemctl start zabbix-agent.service
      when: ansible_service_mgr == 'systemd'
      