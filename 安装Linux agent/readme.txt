
作业名称：
安装Linux agent


剧本附件：
1：install.sh
2：bigagent.tar.gz
备注：bigagent目录不用上传

剧本内容
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 目录授权    
      shell: if [ ! -d /opt/bigops/ ];then sudo mkdir -p /opt/bigops/;sudo chown -R bigops:bigops /opt/bigops/;fi

    - name: 上传文件到远程
      copy: src={{ item }} dest=/opt/bigops/
      with_fileglob:
        - "{{ job_path }}/*"

    - name: 安装    
      shell: /bin/bash /opt/bigops/install.sh

    - name: 创建定时任务    
      cron: name='bigagent' minute=*/1 hour=* day=* month=* weekday=* job='timeout 30 /bin/bash /opt/bigops/bigagent/bigagent.sh >/dev/null 2>&1'

    - name: 运行测试    
      shell: /bin/bash /opt/bigops/bigagent/bigagent.sh


卸载bigagent
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 删除定时任务    
      cron: name='bigagent' state=absent


