#!/bin/bash

### Variables - set password here after adding -p parameter ###
mysql_cmd='mysql -u root'
###

echo "Here the size of databases, where size is above 0 MB (are excluded mysql, schema, etc...):"
$mysql_cmd -N -s -r -e "SELECT table_schema 'Database Name', sum( data_length + index_length ) / 1024 / 1024 'Database Size (MB)' FROM information_schema.TABLES GROUP BY table_schema ;"|sed 's/\..*/MB/'|sed 's/\t/=/'|grep -v '=0MB'

echo "Do you want to have further details for every database? (focus on tables instead of a summary) [y/n]"
read rep
if test "$rep" == "y"
then
	$mysql_cmd -N -s -r -e "SELECT TABLE_SCHEMA AS 'Database_name', TABLE_NAME AS 'Table_Name',CONCAT(ROUND(((DATA_LENGTH + INDEX_LENGTH - DATA_FREE) / 1024 / 1024),2),' Mb') AS Size FROM INFORMATION_SCHEMA.TABLES;"
fi
