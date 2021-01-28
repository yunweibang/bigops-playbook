#!/bin/bash


if [ "$(ps aux|grep java|grep /opt/bigops/bigproxy/bigproxy.jar|grep -Ev '(grep|service|systemctl|.sh)'|wc -l)" -ge 1 ];then     
	ps aux|grep java|grep /opt/bigops/bigproxy/bigproxy.jar|grep -Ev '(grep|service|systemctl|.sh)'|awk '{print $2}'|xargs kill -9
fi     

