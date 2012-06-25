#!/bin/bash

db=sugarcrm
to_character_set=utf8
to_collation=utf8_bin

mysql_cmd="mysql -u root"

######


TBL_LIST=$($mysql_cmd -N -s -r -e "use $db;show tables;")

for tbl_name in $TBL_LIST;
do
$mysql_cmd -e "alter table $db.$tbl_name convert to character set $to_character_set collate to_collation;"
done

echo "Here the result of the operation:"
$mysql_cmd -e "USE $db;SELECT TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, COLLATION_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=DATABASE();"
