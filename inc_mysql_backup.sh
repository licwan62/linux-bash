#!/bin/bash

# 在crontab中调用该脚本
# mysql数据库按照星期日期备份增量，增量基于上个星期日期
# 如周六的最后时刻将基于周五的当天增量数据备份在/new6目录下


TIME=$(date +"%u") #返回星期数字
PWD=

if [ "$TIME" -eq 1 ]; then
    rm -rf /fullbak/*
    xtrabackup --host=127.0.0.1 --user=root --password=$PWD --backup --target-dir=/fullbak --datadir=/var/lib/mysql
fi

if [ "$TIME" -eq 2 ]; then
    rm -rf /new2/*
    xtrabackup --host=127.0.0.1 --user=root --password=$PWD --backup --target-dir=/new2 --incremental-basedir=/fullbak  --datadir=/var/lib/mysql
fi

if [ "$TIME" -eq 3 ]; then
    rm -rf /new3/*
    xtrabackup --host=127.0.0.1 --user=root --password=$PWD --backup --target-dir=/new3 --incremental-basedir=/new2  --datadir=/var/lib/mysql
fi

if [ "$TIME" -eq 4 ]; then
    rm -rf /new4/*
    xtrabackup --host=127.0.0.1 --user=root --password=$PWD --backup --target-dir=/new4 --incremental-basedir=/new3  --datadir=/var/lib/mysql
fi

if [ "$TIME" -eq 5 ]; then
    rm -rf /new5/*
    xtrabackup --host=127.0.0.1 --user=root --password=$PWD --backup --target-dir=/new5 --incremental-basedir=/new4  --datadir=/var/lib/mysql
fi

if [ "$TIME" -eq 6 ]; then
    rm -rf /new6/*
    xtrabackup --host=127.0.0.1 --user=root --password=$PWD --backup --target-dir=/new6 --incremental-basedir=/new5  --datadir=/var/lib/mysql
fi

if [ "$TIME" -eq 7 ]; then
    rm -rf /new7/*
    xtrabackup --host=127.0.0.1 --user=root --password=$PWD --backup --target-dir=/new7 --incremental-basedir=/new6  --datadir=/var/lib/mysql
fi