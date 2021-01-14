作业名称：
安装winlogbeat_windows

剧本附件
1：winlogbeat-7.6.1-windows-x86.zip
2：winlogbeat.yml

winlogbeat官网下载地址，供参考：
https://www.elastic.co/cn/downloads/beats/winlogbeat

变量内容
dest_path="c:/Program Files (x86)/"
unarchive_file="winlogbeat-7.6.1-windows-x86.zip"
unzip_dir="winlogbeat-7.6.1-windows-x86"
conf_file="winlogbeat.yml"
logstash_server="xxx.xxx.xxx.xxx:6515"

剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 关闭服务
      win_shell: taskkill /f /im winlogbeat.exe
      ignore_errors: yes

    - name: 删除源安装目录
      win_file:
        dest: "{{ dest_path }}/winlogbeat"
        state: absent
      ignore_errors: yes
        
    - name: 上传文件到远程
      win_copy: src={{ job_path }}/{{ unarchive_file }} dest={{ dest_path }}

    - name: 解压安装文件
      win_unzip:
        src: "{{ dest_path }}/{{ unarchive_file }}"
        dest: "{{ dest_path }}"
        creates: yes
        delete_archive: yes

    - name: 改名解压目录
      win_shell: chdir={{ dest_path }} cmd /c move /Y "{{ unzip_dir }}" "{{ dest_path }}/winlogbeat"

    - name: 生成时间戳
      shell: date +%Y%m%d%H%M%S%N
      delegate_to: localhost
      register: exec_time
      
    - name: 本地拷贝配置模板
      shell: cp -f {{ job_path }}/{{ conf_file }} {{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}
      delegate_to: localhost
      
    - name: 配置文件格式转换unix2dos
      shell: unix2dos {{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}
      delegate_to: localhost

    - name: 拷贝配置
      win_copy: 
        src:  "{{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}"
        dest: "{{ dest_path }}/winlogbeat/winlogbeat.yml"
        
    - name: 注入Logstash IP到配置
      win_lineinfile:
        path: "{{ dest_path }}/winlogbeat/winlogbeat.yml"
        regex: '  hosts:'
        line: '  hosts: ["{{ logstash_server }}"]'

    - name: 注册服务 
      win_shell: 'PowerShell.exe -file "{{ dest_path }}/winlogbeat/install-service-winlogbeat.ps1"'

    - name: 启动服务 
      win_shell: net start winlogbeat


