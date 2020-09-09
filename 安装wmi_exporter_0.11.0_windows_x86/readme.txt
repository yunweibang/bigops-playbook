作业名称：
安装wmi_exporter-0.11.0-386

系统类型：
Windows


剧本附件
1：wmi_exporter-0.11.0-386.exe
2：syskey.ps1、userkey.ps1

wmi_exporter官网下载地址，供参考：
https://github.com/martinlindhe/wmi_exporter/releases


变量内容
dest_path="c:/Program Files (x86)/wmi_exporter/"  #目标安装路径
exe_file="wmi_exporter-0.11.0-386.exe"  #源文件名


剧本内容
---
- name: example
  hosts: all
  gather_facts: no
    
  tasks:
    - name: 关闭服务
      win_shell: taskkill /f /im wmi_exporter.exe
      ignore_errors: yes

    - name: 创建目录
      win_file:
        path: "{{ dest_path }}/key/"
        state: directory

    - name: 上传文件到远程
      win_copy: src={{ job_path }}/{{ item }} dest={{ dest_path }}/key/
      with_items:
        - syskey.ps1
        - userkey.ps1
      
    - name: 上传文件到远程
      win_copy: src={{ job_path }}/wmi_exporter-0.11.0-386.exe dest={{ dest_path }}
    
    - name: 修改文件名
      win_shell: chdir={{ dest_path }} cmd /c move /Y {{ exe_file }} wmi_exporter.exe

    - name: 删除服务
      win_shell: cmd.exe /c sc delete "WMI exporter"
      ignore_errors: yes
      
    - name: 安装服务
      win_shell: cmd.exe /c sc create "WMI exporter" binPath='\"{{ dest_path }}/wmi_exporter.exe\" --telemetry.addr :9100   --collectors.enabled=\"cpu,cs,logical_disk,net,os,service,system,textfile,tcp\" --collector.textfile.directory \"{{ dest_path }}/key/\"' start=auto
      ignore_errors: yes
    
    - name: 启动服务
      win_shell: net start "WMI exporter"
      
    - name: 创建系统脚本计划任务
      win_shell: cmd.exe /c schtasks /create /F /sc minute /mo 1 /NP /RL HIGHEST /tn "wmi_exporter_syskey" /tr 'PowerShell.exe -file \"{{ dest_path }}/key/syskey.ps1\"'
      ignore_errors: yes

    - name: 创建自定义脚本计划任务
      win_shell: cmd.exe /c schtasks /create /F /sc minute /mo 1 /NP /RL HIGHEST /tn "wmi_exporter_userkey" /tr 'PowerShell.exe -file \"{{ dest_path }}/key/userkey.ps1\"'
      ignore_errors: yes   




