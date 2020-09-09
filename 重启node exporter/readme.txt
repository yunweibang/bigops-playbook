作业名称：重启node exporter

注意：作业名称必须带关键字exporter

系统类型：
Linux

剧本内容
---
- name: example
  hosts: all
  gather_facts: no

  tasks:
    - name: 收集信息
      setup:
        gather_subset:
          - min
          
    - name: 重启node exporter
      shell: |
        systemctl enable node_exporter
        systemctl restart node_exporter
      when: ansible_service_mgr == 'systemd'
  
    - name: 重启node exporter
      shell: |
        chkconfig --level 345 node_exporter on
        service node_exporter restart
      when: ansible_service_mgr != 'systemd'
      
