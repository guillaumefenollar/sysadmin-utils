#!/bin/bash

## Built to work a on XWiki Schema (3.x or 4.x)
nbcoms=50  ## Number of comments above which you get alerted (Spam Threshold).

MYSQL_COMMAND="mysql"
DATABASES=$($MYSQL_COMMAND -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$) ## You can exclude DBs from the list here (adding a grep -v)

for db in $DATABASES
do

CHECK_COMMANDS=$($MYSQL_COMMAND -e "use $db; select count(XWO_NAME) as coms,XWO_NAME as doc from xwikiobjects where XWO_CLASSNAME='XWiki.XWikiComments' GROUP BY XWO_NAME HAVING coms >= $nbcoms;")

        if [[ $CHECK_COMMANDS != "" ]]
        then
                echo "We have found more than $nbcoms comments in database  *** $db *** :"
                $MYSQL_COMMAND -e "use $db; select count(XWO_NAME) as coms,XWO_NAME as doc from xwikiobjects where XWO_CLASSNAME='XWiki.XWikiComments' GROUP BY XWO_NAME HAVING coms >= $nbcoms;"
        fi
                echo ""

done



################
###############   - VSERVER UNDER  -    #########
################


#!/bin/bash

## Built to work a on XWiki Schema (3.x or 4.x)
nbcoms=50  ## Number of comments above which you get alerted (Spam Threshold).

for vm in $(ls -1 /etc/vservers/|grep -v newvserver|grep -v ip.list)
do

echo "Checking VM $vm         ############################################################### "
MYSQL_COMMAND="vserver $vm exec mysql"
DATABASES=$($MYSQL_COMMAND -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$) ## You can exclude DBs from the list here (adding a grep -v)

	for db in $DATABASES
	do
	CHECK_COMMANDS=$($MYSQL_COMMAND -e "use $db; select count(XWO_NAME) as coms,XWO_NAME as doc from xwikiobjects where XWO_CLASSNAME='XWiki.XWikiComments' GROUP BY XWO_NAME HAVING coms >= $nbcoms;")

	        if [[ $CHECK_COMMANDS != "" ]]
	        then
        	        echo "We have found more than $nbcoms comments in database  *** $db *** :"
                	$MYSQL_COMMAND -e "use $db; select count(XWO_NAME) as coms,XWO_NAME as doc from xwikiobjects where XWO_CLASSNAME='XWiki.XWikiComments' GROUP BY XWO_NAME HAVING coms >= $nbcoms;"
        	fi
	                echo ""
	done

done
