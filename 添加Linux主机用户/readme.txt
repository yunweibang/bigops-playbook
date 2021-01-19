
作业名称：添加Linux主机用户

剧本内容：
---
- hosts: all
  gather_facts: no
  vars: 
    user_name: root  //要创建的用户
    user_pass: xxxxx  //用户密码

  tasks:
  - name: 创建用户
    shell: sudo useradd "{{ user_name }}"
  - name: 设置密码
    shell: echo "{{ user_pass }}" | sudo passwd --stdin "{{ user_name }}"

