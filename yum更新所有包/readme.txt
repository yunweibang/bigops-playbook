
作业名称：yum更新所有包

剧本内容：
---
- hosts: all
  gather_facts: no

  tasks:
    - name: yum更新所有包
      shell: yum update -y
