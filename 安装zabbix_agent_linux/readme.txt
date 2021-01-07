作业名称：
安装zabbix_agent_linux

剧本附件
1：zabbix_agentd
2：zabbix_get
3：zabbix_sender
4：zabbix_agentd.conf

附件生成方法，供参考：
源代码下载，地址：https://www.zabbix.com/download
静态编译：
yum -y install glibc-static libcurl-devel pcre*
wget https://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz
tar zxvf automake-1.15.tar.gz
cd automake-1.15
./configure --docdir=/usr/share/doc/automake-1.15
make && make install
tar zxvf zabbix-x.x.x.tar.gz
cd zabbix-x.x.x
./configure --prefix=/usr --sysconfdir=/etc/zabbix --enable-agent --enable-static
make install

把zabbix_agentd、zabbix_get、zabbix_sender、zabbix_agentd.conf先拷贝到笔记本上，然后通过web上传到剧本附件


变量内容
Server="172.31.173.22"
ServerActive="172.31.173.22"


剧本内容
---
- hosts: all
  gather_facts: no
  
  tasks:
    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/usr/bin/
      with_fileglob:
        - "{{ job_path }}/zabbix_sender"
        - "{{ job_path }}/zabbix_get"

    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/usr/sbin/
      with_fileglob:
        - "{{ job_path }}/zabbix_sender"
        - "{{ job_path }}/zabbix_get"

    - name: 创建/etc/zabbix目录   
      shell: if [ ! -d /etc/zabbix/ ];then mkdir /etc/zabbix/;fi

    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/etc/zabbix/
      with_items: 
        - "{{ job_path }}/zabbix_agentd.conf"
        - "{{ job_path }}/zabbix-agent.init"
        - "{{ job_path }}/zabbix-agent.service"
        - "{{ job_path }}/install.sh"

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

    - name: 安装    
      shell: /bin/sh /etc/zabbix/install.sh

      
      
      