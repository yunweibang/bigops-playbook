安装wmi_exporter-0.11.0-386


剧本附件
1、wmi_exporter-0.11.0-386.exe
下载地址：https://github.com/martinlindhe/wmi_exporter/tree/v0.11.0

2、syskey.ps1
下载地址：当前仓库

3、userkey.ps1
下载地址：当前仓库


变量内容
exe_file="wmi_exporter-0.11.0-386.exe"  #源文件名
syskey_file="/opt/bigops/job/{{ job_id }}/syskey.ps1"  #生成系统key脚本
userkey_file="/opt/bigops/job/{{ job_id }}/userkey.ps1"  #生成自定义key脚本
src_file="/opt/bigops/job/{{ job_id }}/{{ exe_file }}"  #源文件
dest_dir="c:/Program Files (x86)/wmi_exporter/"  #源文件拷贝目录


剧本内容
---
- name: example
  hosts: all
  gather_facts: no
    
  tasks:
    - name: 关闭服务
      win_shell: net stop "WMI exporter"
      ignore_errors: yes
      
    - name: 拷贝文件
      win_copy: 
        src:  "{{ src_file }}"
        dest: "{{ dest_dir }}"

    - name: 创建key目录
      win_file:
        path: "{{ dest_dir }}/key/"
        state: directory
        
    - name: 拷贝系统key脚本
      win_copy: 
        src:  "{{ syskey_file }}"
        dest: "{{ dest_dir }}/key/"
        
    - name: 拷贝自定义key脚本
      win_copy: 
        src:  "{{ userkey_file }}"
        dest: "{{ dest_dir }}/key/"

    - name: 修改文件名
      win_shell: chdir={{ dest_dir }} cmd /c move /Y {{ exe_file }} wmi_exporter.exe

    - name: 删除服务
      win_shell: cmd.exe /c sc delete "WMI exporter"
      ignore_errors: yes
      
    - name: 安装服务
      win_shell: cmd.exe /c sc create "WMI exporter" binPath='\"{{ dest_dir }}/wmi_exporter.exe\" --telemetry.addr :9100   --collectors.enabled=\"cpu,cs,logical_disk,net,os,service,system,textfile,tcp\" --collector.textfile.directory \"{{ dest_dir }}/key/\"' start=auto
      ignore_errors: yes
    
    - name: 启动服务
      win_shell: net start "WMI exporter"
      
    - name: 创建系统脚本计划任务
      win_shell: cmd.exe /c schtasks /create /F /sc minute /mo 1 /NP /RL HIGHEST /tn "wmi_exporter_syskey" /tr 'PowerShell.exe -file \"{{ dest_dir }}/key/syskey.ps1\"'
      ignore_errors: yes

    - name: 创建自定义脚本计划任务
      win_shell: cmd.exe /c schtasks /create /F /sc minute /mo 1 /NP /RL HIGHEST /tn "wmi_exporter_userkey" /tr 'PowerShell.exe -file \"{{ dest_dir }}/key/userkey.ps1\"'
      ignore_errors: yes   


