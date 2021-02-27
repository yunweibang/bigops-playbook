
作业名称：
设置rsyslog


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
    - name: 检查logstash_ip变量
      shell: echo {{ logstash_ip }}
      register: return_value
    - debug:
        msg: "logstash_ip变量不能为空！"
      when: return_value.stdout  == ""
      failed_when:  return_value.stdout  == ""

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
      
