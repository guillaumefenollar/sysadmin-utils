#!/bin/bash

MYSQL_COMMAND=mysql
TO_ENGINE=INNODB

DATABASES=$(mysql -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$)


for db in $DATABASES
do

echo "Working on database $db..."
echo ""

TABLES=$(mysql -N -s -r -e "show tables from $db;")

for tb in $TABLES
do

$MYSQL_COMMAND -e "ALTER TABLE $db.$tb ENGINE = $TO_ENGINE;"

done

echo "" 
echo ""

done
