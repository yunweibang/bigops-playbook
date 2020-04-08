#!/bin/bash

 
/opt/exporter/mysqld_exporter/mysqld_exporter --web.listen-address=":9104" --config.my-cnf="/opt/exporter/mysqld_exporter/172.31.173.22.cnf" &

#/opt/exporter/mysqld_exporter/mysqld_exporter --web.listen-address=":9105" --config.my-cnf="/opt/exporter/mysqld_exporter/172.31.173.23.cnf" &

#/opt/exporter/mysqld_exporter/mysqld_exporter --web.listen-address=":9106" --config.my-cnf="/opt/exporter/mysqld_exporter/172.31.173.24.cnf" &