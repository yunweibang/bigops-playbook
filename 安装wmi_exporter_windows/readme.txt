
作业名称：
安装windows_exporter


官网：
https://github.com/prometheus-community/windows_exporter


剧本附件：
1：windows_exporter-0.15.0-386.exe
2：syskey.ps1

模板变量：
dest_path="c:/Program Files (x86)/windows_exporter/"
exe_file="windows_exporter-0.15.0-386.exe"


剧本内容：
---
- name: example
  hosts: all
  gather_facts: no
    
  tasks:
    - name: 关闭服务
      win_shell: taskkill /f /im wmi_exporter.exe
      ignore_errors: yes

    - name: 关闭服务
      win_shell: taskkill /f /im windows_exporter.exe
      ignore_errors: yes

    - name: 创建目录
      win_file:
        path: "{{ dest_path }}/key/"
        state: directory

    - name: 上传文件到远程
      win_copy: src={{ job_path }}/{{ item }} dest={{ dest_path }}/key/
      with_items:
        - syskey.ps1
      
    - name: 上传文件到远程
      win_copy: src={{ job_path }}/{{ exe_file }} dest={{ dest_path }}
    
    - name: 修改文件名
      win_shell: chdir={{ dest_path }} cmd /c move /Y {{ exe_file }} windows_exporter.exe

    - name: 删除服务
      win_shell: cmd.exe /c sc delete "WMI exporter"
      ignore_errors: yes

    - name: 删除服务
      win_shell: cmd.exe /c sc delete "windows exporter"
      ignore_errors: yes
      
    - name: 安装服务
      win_shell: cmd.exe /c sc create "windows exporter" binPath='\"{{ dest_path }}/windows_exporter.exe\" --telemetry.addr :9100   --collectors.enabled=\"cpu,cs,logical_disk,net,os,process,service,tcp,system,textfile\" --collector.textfile.directory \"{{ dest_path }}/key/\"' start=auto
      ignore_errors: yes
    
    - name: 启动服务
      win_shell: net start "windows exporter"
      
    - name: 创建系统脚本计划任务
      win_shell: cmd.exe /c schtasks /create /F /sc minute /mo 1 /NP /RL HIGHEST /tn "windows_exporter" /tr 'PowerShell.exe -file \"{{ dest_path }}/key/syskey.ps1\"'
      ignore_errors: yes






