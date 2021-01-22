
作业名称：
安装Linux agent


剧本附件：
1：bigagent.sh
2：hostinfo.sh
3：install.sh
4：soft_version.sh


剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 创建/opt/bigops/bigagent目录
      shell: if [ ! -d /opt/bigops/bigagent/bin ];then sudo mkdir -p /opt/bigops/bigagent/bin;fi
      
    - name: 上传文件到远程目录
      copy: src={{ item }} dest=/opt/bigops/bigagent
      with_fileglob:
        - "{{ job_path }}/*"

    - name: 授权/opt/bigops目录
      shell: sudo chown -R bigops:bigops /opt/bigops

    - name: 拷贝命令到bin目录
      shell: cd /opt/bigops/bigagent/;mv -f dmidecode ipmitool lsb_release MegaCli64 mpstat netstat rsync smartctl ss ss_c6 virt-what /opt/bigops/bigagent/bin/
     
    - name: 添加cron
      cron: name='bigagent' minute=*/1 hour=* day=* month=* weekday=* job='timeout 30 /bin/bash /opt/bigops/bigagent/bigagent.sh >/dev/null 2>&1'

    - name: 运行bigagent脚本
      shell: /bin/bash /opt/bigops/bigagent/bigagent.sh


卸载bigagent
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 删除cron
      cron: name='bigagent' state=absent

    - name: 删除目录
      shell: rm -rf /opt/bigops/bigagent
