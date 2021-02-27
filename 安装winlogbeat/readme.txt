
作业名称：
安装winlogbeat


官网：
https://www.elastic.co/cn/downloads/beats/winlogbeat


剧本附件：
1：winlogbeat-7.6.1-windows-x86.zip
2：winlogbeat.yml


模板变量：
logstash_ip=""
logstash_port="6515"
unarchive_file="winlogbeat-7.11.1-windows-x86.zip"
unzip_dir="winlogbeat-7.11.1-windows-x86"


剧本内容：
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 检查logstash_ip变量
      win_shell: echo "{{ logstash_ip }}"
      register: return_value
    - debug:
        msg: "logstash_ip变量不能为空！"
      when: return_value.stdout  == "\r\n"
      failed_when: return_value.stdout  == "\r\n"
      
    - name: 关闭服务
      win_shell: taskkill /f /im winlogbeat.exe
      ignore_errors: yes

    - name: 删除源安装目录
      win_file:
        dest: "c:/Program Files/winlogbeat"
        state: absent
      ignore_errors: yes
        
    - name: 上传文件到远程
      win_copy: src={{ job_path }}/{{ unarchive_file }} dest="c:/Program Files/"

    - name: 解压安装文件
      win_unzip:
        src: "c:/Program Files/{{ unarchive_file }}"
        dest: "c:/Program Files/"
        creates: yes
        delete_archive: yes

    - name: 改名解压目录
      win_shell: chdir="c:/Program Files/" cmd /c move /Y "{{ unzip_dir }}" "c:/Program Files/winlogbeat"

    - name: 生成时间戳
      shell: date +%Y%m%d%H%M%S%N
      delegate_to: localhost
      register: exec_time
      
    - name: 本地拷贝配置模板
      shell: cp -f {{ job_path }}/winlogbeat.yml {{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}
      delegate_to: localhost
      
    - name: 配置文件格式转换unix2dos
      shell: unix2dos {{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}
      delegate_to: localhost

    - name: 拷贝配置
      win_copy: 
        src:  "{{ temp_path }}/winlogbeat_{{ inventory_hostname }}_{{ exec_time.stdout }}"
        dest: "c:/Program Files/winlogbeat/winlogbeat.yml"
        
    - name: 注入Logstash IP到配置
      win_lineinfile:
        path: "c:/Program Files/winlogbeat/winlogbeat.yml"
        regex: '  hosts:'
        line: '  hosts: ["{{ logstash_ip }}:{{ logstash_port }}"]'

    - name: 注册服务 
      win_shell: 'PowerShell.exe -file "c:/Program Files/winlogbeat/install-service-winlogbeat.ps1"'

    - name: 启动服务 
      win_shell: net start winlogbeat


