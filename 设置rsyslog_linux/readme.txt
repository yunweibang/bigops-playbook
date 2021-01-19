
作业名称：
设置rsyslog_linux


变量内容：
logstash_ip=""
logstash_port="6514"
facility='*'
priority="notice"


剧本内容：
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 授权目录
      shell: ls -l /etc/rsyslog.d
      register: list
    - debug: var=list.stdout_lines

    - name: 生成配置文件
      shell: sudo sh -c 'echo "{{ facility }}.{{ priority }} @@{{ logstash_ip }}:{{ logstash_port }}" > /etc/rsyslog.d/bigops.conf'

    - name: 查看配置文件
      shell: cat /etc/rsyslog.d/bigops.conf
      register: rsyslog
    - debug: var=rsyslog.stdout_lines

    - name: 重启服务
      shell: if [ -f /usr/bin/systemctl ];then sudo systemctl restart rsyslog;else sudo service rsyslog restart;fi

    - name: 发送测试信息
      shell: logger -i -t 'bigops' -p local3.error 'bigops test'

      
