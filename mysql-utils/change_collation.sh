#!/bin/bash

mysql_cmd=mysql -u root -p

TBL_LIST=$($mysql_cmd -N -s -r -e 'use xwiki;show tables;')

for tbl_name in $TBL_LIST;
do
$mysql_cmd -e "alter table xwiki.$tbl_name convert to character set utf8 collate utf8_bin;"
done

echo "Here the result of the operation:"
$mysql_cmd -e 'SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, COLLATION_NAME     FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA="xwiki";'
