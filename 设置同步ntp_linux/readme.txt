
作业名称:
设置同步ntp服务器


剧本内容:
---
- hosts: all
  gather_facts: no

  tasks:
    - name: 删除已有同步
      shell: sudo sed -i '/.*ntpdate.*/d' /var/spool/cron/root

    - name: 添加新同步
      shell: sudo sh -c 'echo "* */6 * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1" >> /var/spool/cron/root'




      
