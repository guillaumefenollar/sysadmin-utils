#!/bin/bash

MYSQL_COMMAND=mysql

DATABASES=$(mysql -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$)

for db in $DATABASES
do
$MYSQL_COMMAND -e "use $db; SELECT table_schema,table_name,Engine,table_collation FROM information_schema.tables WHERE table_schema = DATABASE() AND table_collation <> 'utf8_bin'"
done


