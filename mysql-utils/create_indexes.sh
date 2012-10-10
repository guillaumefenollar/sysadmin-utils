#!/bin/bash
# This script help to create activity stream index which is missing in XWiki version <4.2
##CONFIG##
mysql_cmd="mysql -u root"
log_file=".$0.log"
##
##INDEXES## format is : one index per line. name of the index, table, column name. ; separated.

INDEXES="xwl_value;xwikilargestrings;(xwl_value(50))
xwd_parent;xwikidoc;(xwd_parent(50))
xwd_class_xml;xwikidoc;(xwd_class_xml(20))
xwr_isdiff;xwikircs;(xwr_isdiff)
xws_number;xwikistatsdoc;(XWS_NUMBER)
xws_classname;xwikistatsdoc;(XWS_CLASSNAME)
xwr_number;xwikistatsreferer;(XWR_NUMBER)
xwr_classname;xwikistatsreferer;(XWR_CLASSNAME)
xwr_referer;xwikistatsreferer;(XWR_REFERER(50))
xwv_user_agent;xwikistatsvisit;(XWV_USER_AGENT(255))
xwv_cookie;xwikistatsvisit;(XWV_COOKIE(255))
xwv_classname;xwikistatsvisit;(XWV_CLASSNAME)
xwv_number;xwikistatsvisit;(XWV_NUMBER)
ase_requestid;activitystream_events;(ase_requestid(200))
ase_page_date;activitystream_events;(ase_page,ase_date)
xda_docid1;xwikiattrecyclebin;(xda_docid)"

DATABASES="$($mysql_cmd -N -s -e "show databases")"

exec 2>&1 1> $log_file

for db in $DATABASES
do
   if [[ "$($mysql_cmd -N -s -e "use $db;show tables" |grep xwikidoc)" == "" ]]
   then
 	echo "Database $db is not a valid XWiki Database"
   else

	for i in $INDEXES
	do
		tb="$(echo $i|cut -d';' -f2)"
		name_i="$(echo $i|cut -d';' -f1)"
		col_i="$(echo $i|cut -d';' -f3)"

		HAS_INDEX="$($mysql_cmd -N -s -e "use $db; show index from $tb"|grep $name_i)"

	if [[ $HAS_INDEX == "" ]]
	then
		$mysql_cmd -N -s -e "ALTER TABLE $db.$tb ADD INDEX $name_i$col_i;"
	else
		echo "$name_i for $tb (database $db) is already there"
	fi
	done
   fi
done
