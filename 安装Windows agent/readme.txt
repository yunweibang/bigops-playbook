
作业名称：
安装Windows agent

排错
cd "C:\Program Files\bigagent"
net stop bigagent
set debug=123
bigagent run


剧本附件：
1：bigagent.exe

剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 停止bigagent服务
      win_command: net stop bigagent
      ignore_errors: true

    - name: 卸载bigagent服务
      win_command: \"C:/Program Files/bigagent/bigagent.exe\" uninstall
      ignore_errors: true

    - name: 上传文件到远程目录
      win_copy: src='/opt/bigops/packages/Windows/bigagent.exe' dest='C:/Program Files/bigagent/bigagent.exe'

    - name: 安装bigagent服务
      win_command: \"C:/Program Files/bigagent/bigagent.exe\" install

    - name: 启动bigagent服务
      win_command: net start bigagent

    - name: 添加计划任务
      win_command: net start bigagent



卸载bigagent
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 卸载bigagent服务
      win_command: \"C:/Program Files/bigagent/bigagent.exe\" uninstall


