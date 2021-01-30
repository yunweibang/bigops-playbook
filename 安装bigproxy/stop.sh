#!/bin/bash


if [ "$(ps aux|grep /opt/bigops/bigproxy/bigproxy.jar|grep -v grep|wc -l)" -ge 1 ];then     
	ps aux|grep /opt/bigops/bigproxy/bigproxy.jar|grep -v grep|awk '{print $2}'|xargs kill -9
fi     

