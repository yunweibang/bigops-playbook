安装winlogbeat-7.6.1-windows-x86


剧本附件
1、winlogbeat-7.6.1-windows-x86.zip
下载地址：https://www.elastic.co/cn/downloads/beats/winlogbeat

2、winlogbeat.yml
当前仓库下载


变量内容
logstash_server="172.31.173.22:6515"  #Logstash服务器IP和端口，修改为你的
zip_file="winlogbeat-7.6.1-windows-x86.zip"  #压缩包文件名
src_file="/opt/bigops/job/{{ job_id }}/{{ zip_file }}"  #安装文件
config_file="/opt/bigops/job/{{ job_id }}/winlogbeat.yml"  #配置模板文件
unzip_dir="winlogbeat-7.6.1-windows-x86"  #解压目录
install_path="c:/Program Files (x86)/"  #安装路径
install_dir="winlogbeat"  #安装目录


剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 关闭服务
      win_shell: net stop winlogbeat
      ignore_errors: yes

    - name: 拷贝安装文件
      win_copy: 
        src: "{{ src_file }}"
        dest: "{{ install_path }}"

    - name: 解压安装文件
      win_unzip:
        src: "{{ install_path }}/{{ zip_file }}"
        dest: "{{ install_path }}"
        creates: yes
        delete_archive: yes

    - name: 删除源安装目录
      win_file:
        dest: "{{ install_path }}/{{ install_dir }}"
        state: absent
      ignore_errors: yes
      
    - name: 改名解压目录
      win_shell: chdir={{ install_path }} cmd /c move /Y "{{unzip_dir}}" "{{install_dir}}"

    - name: 生成时间戳
      shell: date +%Y%m%d%H%M%S%N
      delegate_to: localhost
      register: exec_time

    - name: 拷贝配置模板
      shell: cp -f {{ config_file }} {{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}
      delegate_to: localhost
      
    - name: 配置文件格式转换unix2dos
      shell: unix2dos {{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}
      delegate_to: localhost

    - name: 拷贝配置
      win_copy: 
        src:  "{{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}"
        dest: "{{ install_path }}/{{ install_dir }}/winlogbeat.yml"
        
    - name: 注入Logstash IP到配置
      win_lineinfile:
        path: "{{ install_path }}/{{ install_dir }}/winlogbeat.yml"
        regex: '  hosts:'
        line: '  hosts: ["{{ logstash_server }}"]'

    - name: 注册服务 
      win_shell: "& \'{{ install_path }}/{{ install_dir }}/install-service-winlogbeat.ps1\'"

    - name: 启动服务 
      win_shell: net start winlogbeat

