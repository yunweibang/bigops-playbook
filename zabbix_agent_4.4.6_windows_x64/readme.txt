安装zabbix_agent-4.4.6-windows-i386


剧本附件
1、zabbix_agent-4.4.6-windows-i386.zip
下载地址：https://www.zabbix.com/download

2、zabbix_agentd.conf
解压zabbix_agent-4.4.6-windows-i386.zip文件，提取conf目录下的zabbix_agentd.conf，修改为配置模板


变量内容
zip_file="zabbix_agent-4.4.6-windows-i386.zip"  #压缩包文件名
src_file="/opt/bigops/job/{{ job_id }}/{{ zip_file }}"  #压缩包路径
config_file="/opt/bigops/job/{{ job_id }}/zabbix_agentd.conf"  #配置模板文件
install_path="c:/Program Files (x86)/"  #安装路径
install_dir="zabbix_agent"  #安装目录名


剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 关闭服务
      win_shell: net stop "Zabbix Agent"
      ignore_errors: yes
      
    - name: 卸载服务
      win_shell: chdir={{ install_path }}/{{ install_dir }}/bin/ ./zabbix_agentd.exe -d -c ../conf/zabbix_agentd.conf
      ignore_errors: yes

    - name: 删除前安装目录
      win_file:
        dest: "{{ install_path }}/{{ install_dir }}"
        state: absent
      ignore_errors: yes
      
    - name: 拷贝安装文件
      win_copy: 
        src:  "{{ src_file }}"
        dest: "{{ install_path }}"
 
    - name: 解压文件
      win_unzip:
        src: "{{ install_path }}/{{ zip_file }}"
        dest: "{{ install_path }}/{{ install_dir }}/"
        creates: yes
        delete_archive: yes

    - name: 生成时间戳
      shell: date +%Y%m%d%H%M%S%N
      delegate_to: localhost
      register: exec_time

    - name: 本地拷贝配置模板
      shell: cp -f {{ config_file }} {{ temp_path }}/zabbix_agent_{{ inventory_hostname }}_{{ exec_time.stdout }}
      delegate_to: localhost
      
    - name: 注入Hostname配置
      shell: echo 'Hostname={{ inventory_hostname }}' >> "{{ temp_path }}/zabbix_agent_{{ inventory_hostname }}_{{ exec_time.stdout }}"
      delegate_to: localhost

    - name: 配置文件转换格式unix2dos
      shell: unix2dos "{{ temp_path }}/zabbix_agent_{{ inventory_hostname }}_{{ exec_time.stdout }}"
      delegate_to: localhost

    - name: 拷贝配置到客户端
      win_copy: 
        src: "{{ temp_path }}/zabbix_agent_{{ inventory_hostname }}_{{ exec_time.stdout }}"
        dest: "{{ install_path }}/{{ install_dir }}/conf/zabbix_agentd.conf"

    - name: 注册服务 
      win_shell: chdir={{ install_path }}/{{ install_dir }}/bin/ ./zabbix_agentd.exe -i -c ../conf/zabbix_agentd.conf

    - name: 启动服务 
      win_command: net start "Zabbix Agent"

      