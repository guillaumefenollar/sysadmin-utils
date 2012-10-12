#!/bin/bash
# This script help to create activity stream index which is missing in XWiki version <4.2
##CONFIG##
mysql_cmd="mysql -u root"
log_file="$0.log"
##
##INDEXES## format is : one index per line. name of the index, table, column name. ; separated.

INDEXES="XWL_VALUE;xwikilargestrings;(xwl_value(50))
XWD_PARENT;xwikidoc;(xwd_parent(50))
XWD_CLASS_XML;xwikidoc;(xwd_class_xml(20))
XWR_ISDIFF;xwikircs;(xwr_isdiff)
XWS_NUMBER;xwikistatsdoc;(XWS_NUMBER)
XWS_CLASSNAME;xwikistatsdoc;(XWS_CLASSNAME)
XWR_NUMBER;xwikistatsreferer;(XWR_NUMBER)
XWR_CLASSNAME;xwikistatsreferer;(XWR_CLASSNAME)
XWR_REFERER;xwikistatsreferer;(XWR_REFERER(50))
XWV_USER_AGENT;xwikistatsvisit;(XWV_USER_AGENT(255))
XWV_COOKIE;xwikistatsvisit;(XWV_COOKIE(255))
XWV_CLASSNAME;xwikistatsvisit;(XWV_CLASSNAME)
XWV_NUMBER;xwikistatsvisit;(XWV_NUMBER)
ASE_REQUESTID;activitystream_events;(ase_requestid(200))
ASE_PAGE_DATE;activitystream_events;(ase_page,ase_date)
XDA_DOCID1;xwikiattrecyclebin;(xda_docid)"

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

		HAS_INDEX="$($mysql_cmd -N -s -e "use $db; show index from $tb where column_name="$col_i";")"

	if [[ $HAS_INDEX == "" ]]
	then
		echo "Creating index for table $tb, column $col_i"
		$mysql_cmd -N -s -e "ALTER TABLE $db.$tb ADD INDEX $name_i$col_i;" 1>/dev/null
	elif [[ $HAS_INDEX == ]]
	then

	else
		echo "$name_i for $tb (database $db) is already there"
	fi
	done
   fi
done
