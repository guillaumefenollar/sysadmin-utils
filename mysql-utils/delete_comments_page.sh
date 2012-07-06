#!/bin/bash
#
## Variables
PAGE='"Blog.Blog Action Day WaterWiki"'
DB="xwiki"
#


spam=$(mysql -N -e "use $DB;select XWO_ID from xwikiobjects where XWO_NAME=$PAGE and XWO_CLASSNAME='XWiki.XWikiComments';")
ERRCODE=0
DELETED=0
## For each comment on the page, we delete it from the six tables
for ID in $spam
do

mysql -e "use $DB;delete from xwikidates where XWS_ID = $ID; delete from xwikistrings where XWS_ID = $ID; delete from xwikilargestrings where XWL_ID = $ID; delete from xwikiintegers where XWI_ID = $ID; delete from xwikiproperties where XWP_ID = $ID; delete from xwikiobjects where XWO_ID = $ID;"
if [[ $? != 0 ]]
then
        ERRCODE=1
else
        DELETED=`expr $DELETED + 1`
fi
done
#

## Report and ending
if [[ $ERRCODE == 1 ]]
then
        echo "A problem occured during the comments deletion"
else
        echo "OK - $DELETED comments deleted"
fi
#
