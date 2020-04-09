安装zabbix_agent-4.4.6-windows-i386


剧本附件
1、zabbix_agent-4.4.6-windows-i386.zip
下载地址：https://www.zabbix.com/download

2、zabbix_agentd.conf
解压zabbix_agent-4.4.6-windows-i386.zip文件，提取conf目录下的zabbix_agentd.conf，修改为配置模板


变量内容
dest_path="c:/Program Files (x86)/"  #目标安装路径
unarchive_file="zabbix_agent-4.4.6-windows-i386.zip"  #压缩包文件名
unzip_dir="zabbix_agent-4.4.6-windows-i386"   #解压目录
Server="172.31.173.22"
ServerActive="172.31.173.22"


剧本内容
----
- hosts: all
  gather_facts: no

  tasks:
    - name: 关闭服务
      win_shell: taskkill /f /im zabbix_agent.exe
      ignore_errors: yes
      
    - name: 卸载服务
      win_shell: chdir={{ dest_path }}/zabbix_agent/bin/ ./zabbix_agentd.exe -d -c ../conf/zabbix_agentd.conf
      ignore_errors: yes

    - name: 删除前安装目录
      win_file:
        dest: "{{ dest_path }}/zabbix_agent"
        state: absent
      ignore_errors: yes
      
    - name: 拷贝安装文件
      win_copy: 
        src:  "{{ job_path }}/{{ unarchive_file }}"
        dest: "{{ dest_path }}"
        
    - name: 解压文件
      win_unzip:
        src: "{{ dest_path }}/{{ unarchive_file }}"
        dest: "{{ dest_path }}/zabbix_agent/"
        creates: yes
        delete_archive: yes
    
    - name: 更新Hostname配置
      win_lineinfile :
        path: "{{ dest_path }}/zabbix_agent/conf/zabbix_agentd.conf"
        regexp: '^Hostname='
        line: 'Hostname={{ inventory_hostname }}'
        backrefs: no
        
    - name: 更新LogFile配置
      win_lineinfile :
        path: "{{ dest_path }}/zabbix_agent/conf/zabbix_agentd.conf"
        regexp: '^LogFile='
        line: 'LogFile={{ dest_path }}/zabbix_agent/zabbix_agentd.log'
        backrefs: no

    - name: 更新Server配置
      win_lineinfile :
        path: "{{ dest_path }}/zabbix_agent/conf/zabbix_agentd.conf"
        regexp: '^Server='
        line: 'Server={{ Server }}'
        backrefs: no

    - name: 更新ServerActive配置
      win_lineinfile :
        path: "{{ dest_path }}/zabbix_agent/conf/zabbix_agentd.conf"
        regexp: '^ServerActive='
        line: 'ServerActive={{ ServerActive }}'
        backrefs: no
        
    - name: 注册服务 
      win_shell: chdir={{ dest_path }}/zabbix_agent/bin/ ./zabbix_agentd.exe -i -c ../conf/zabbix_agentd.conf

    - name: 启动服务 
      win_command: net start "Zabbix Agent"
      
