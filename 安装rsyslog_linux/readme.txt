作业名称：
安装rsyslog

系统类型：
Linux

变量内容
logstash_ip="172.31.173.22"  #Logstash服务器IP，设置为你自己的
logstash_port="6514"  #Logstash服务器端口
facility='*'  #程序模块
priority=notice  #日志级别


剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 生成配置文件
      shell: echo "{{ facility }}.{{ priority }} @@{{ logstash_ip }}:{{ logstash_port }}" > /etc/rsyslog.d/bigops.conf

    - name: 查看配置文件
      shell: cat /etc/rsyslog.d/bigops.conf
      register: rsyslog
    - debug: var=rsyslog.stdout_lines

    - name: 重启服务
      action: service
        name=rsyslog
        state=restarted

    - name: 发送测试信息
      shell: logger -i -t 'bigops' -p local3.error 'bigops test'

    - name: 测试日志服务器端口状态
      shell: nmap -sU -pU:6514 "{{ logstash_ip }}"
      register: nmap
    - debug: var=nmap.stdout_lines