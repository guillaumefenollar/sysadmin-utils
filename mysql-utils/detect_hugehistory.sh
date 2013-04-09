#!/bin/bash
# This script list on the current mysql instance the pages having a huge history.
#
# VARS
threshold="1000"
mysql_cmd="mysql -uroot"
# # #

DATABASES=$($mysql_cmd -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$)

for db in $DATABASES
do
   if [[ "$($mysql_cmd -N -s -e "use $db;show tables" |grep xwikidoc)" == "" ]]
   then
 	echo "Database $db is not a valid XWiki Database"
   else
	echo "Working on database $db ..."
	$mysql_cmd -N -s -e "use $db; select count(rcs.xwr_docid) as hist,doc.xwd_fullname from xwikircs as rcs, xwikidoc as doc where doc.xwd_id = rcs.xwr_docid group by xwr_docid having hist >= 500;"
   fi
done
