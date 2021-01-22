#!/bin/bash


if [ "$(ps aux|grep java|grep -v grep|grep bigproxy.jar$|wc -l)" -ge 1 ];then     
	ps aux|grep java|grep -v grep|grep bigproxy.jar$|awk '{print $2}'|xargs kill -9
fi     

