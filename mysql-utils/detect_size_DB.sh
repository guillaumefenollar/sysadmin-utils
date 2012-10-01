#!/bin/bash

### Variables - set password here after adding -p parameter ###
mysql_cmd='mysql -u root'
###

echo "Here the size of databases, where size is above 0 MB (are excluded mysql, schema, etc...):"
$mysql_cmd -N -s -r -e "SELECT table_schema 'Database Name', sum( data_length + index_length ) / 1024 / 1024 'Database Size (MB)' FROM information_schema.TABLES GROUP BY table_schema ;"|sed 's/\..*/MB/'|sed 's/\t/=/'|grep -v '=0MB'
