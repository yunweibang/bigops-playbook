
作业名称：重启Windows主机

剧本内容：
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 重启主机
      win_reboot:
