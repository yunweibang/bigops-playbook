
作业名称：重启Linux主机

剧本内容：
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 重启Linux主机
      shell: reboot
