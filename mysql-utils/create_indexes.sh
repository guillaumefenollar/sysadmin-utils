#!/bin/bash
# This script help to create activity stream index which is missing in XWiki version <4.2
##CONFIG##
mysql_cmd="mysql -u root"
log_file="$0.log"
##
##INDEXES## format is : one index per line. name of the index, table, column name, size. : separated.

INDEXES="XWL_VALUE:xwikilargestrings:xwl_value:(50)
XWD_PARENT:xwikidoc:xwd_parent:(50)
XWD_CLASS_XML:xwikidoc:xwd_class_xml:(20)
XWR_ISDIFF:xwikircs:xwr_isdiff
XWS_NUMBER:xwikistatsdoc:xws_number
XWS_CLASSNAME:xwikistatsdoc:xws_classname
XWR_NUMBER:xwikistatsreferer:xwr_number
XWR_CLASSNAME:xwikistatsreferer:xwr_classname
XWR_REFERER:xwikistatsreferer:xwr_referer:(50)
XWV_USER_AGENT:xwikistatsvisit:xwv_user_agent:(255)
XWV_COOKIE:xwikistatsvisit:xwv_cookie:(255)
XWV_CLASSNAME:xwikistatsvisit:xwv_classname
XWV_NUMBER:xwikistatsvisit:xwv_number
ASE_REQUESTID:activitystream_events:ase_requestid:(200)
XDA_DOCID1:xwikiattrecyclebin:xda_docid"

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
	# Putting elements in vars
		tb="$(echo $i|cut -d':' -f2)"
		name_i="$(echo $i|cut -d':' -f1)"
		col_i="$(echo $i|cut -d':' -f3)"
		size="$(echo $i|cut -d':' -f4)"

		HAS_INDEX="$($mysql_cmd -N -s -e "use $db; show index from $tb where column_name=\"$col_i\";")"

	# If no index have been created for this column
	if [[ $HAS_INDEX == "" ]]
	then
		echo "Creating index for table $tb, column $col_i"
		$mysql_cmd -N -s -e "ALTER TABLE $db.$tb ADD INDEX $name_i($col_i$size);" 1>/dev/null
	# If an index already exists with another name (duplicate)
	elif [[ "$(echo "$HAS_INDEX" |wc -l)" -gt 1  ]]
	then
		DUP_INDEX="$($mysql_cmd -N -s -e "use $db; show index from $tb where column_name=\"$col_i\" and key_name != \"$name_i\";")"
		DUP_INDEX_NAME=$(echo $DUP_INDEX|awk '{print $3}')
		$mysql_cmd -N -s -e "use $db; DROP INDEX $DUP_INDEX_NAME ON $tb;"
		echo "A duplicate index for column $col_i on table $tb has been deleted."
	else
	# Index is already created for the column
		echo "$name_i for $tb (database $db) is already there"
	fi
	done
   fi
done
