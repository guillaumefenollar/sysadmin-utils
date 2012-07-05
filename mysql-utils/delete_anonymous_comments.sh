#!/bin/bash
#
## Variables
DB_to_wipe=xwiki
Mysql_Command="mysql -N -s -r -e"
#

## Detect all anonymous comments
comments=$($Mysql_Command "use $DB_to_wipe;select XWO_ID from xwikiobjects, xwikistrings where XWO_ID = XWS_ID and XWS_NAME = 'author' and XWS_VALUE not like 'XWiki.%' and XWS_VALUE not like 'xwiki:XWiki.%';")

nb_coms=$($Mysql_Command "use $DB_to_wipe;select count(XWO_ID) from xwikiobjects, xwikistrings where XWO_ID = XWS_ID and XWS_NAME = 'author' and XWS_VALUE not like 'XWiki.%' and XWS_VALUE not like 'xwiki:XWiki.%';")
echo "There is $nb_coms anonymous comments that will die... NOW!"

## Deleting the comments from the tables
for ID in $comments
do
	$Mysql_Command "use $DB_to_wipe; delete from xwikidates where XWS_ID = $ID; delete from xwikistrings where XWS_ID = $ID; delete from xwikilargestrings where XWL_ID = $ID; delete from xwikiintegers where XWI_ID = $ID; delete from xwikiproperties where XWP_ID = $ID; delete from xwikiobjects where XWO_ID = $ID;"
done

## Checking if they have been all erased
nb_coms=$($Mysql_Command "use $DB_to_wipe;select count(XWO_ID) from xwikiobjects, xwikistrings where XWO_ID = XWS_ID and XWS_NAME = 'author' and XWS_VALUE not like 'XWiki.%' and XWS_VALUE not like 'xwiki:XWiki.%';")
if [[ $nb_coms == "" ]]
then
        echo "There is no anonymous comment alive out there..."
else
        echo "There is still $nb_coms comments remaining"
fi

real_coms=$($Mysql_Command "use $DB_to_wipe; select count(*) from xwikiobjects, xwikistrings where XWO_ID = XWS_ID and XWS_NAME = 'author' and (XWS_VALUE like 'XWiki.%' or XWS_VALUE like 'xwiki:XWiki.%');")
echo "Totally useless information : There is $real_coms real comments"
