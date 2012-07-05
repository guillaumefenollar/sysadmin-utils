#!/bin/bash
#
# This script detect both wrong collation and spam in each table of each database of each running vserver. It finally sends a mail with a global result of the scan
#
#### Variables #
mail_add=guillaume.fenollar@xwiki.com ## To whom send the mail
nbcoms=50 ## Threshold for spam detection (docs with more comments will be flagged as possibly spammed)
errfile="$0.err"
mailfile="$0.mail"
#

exec 2> $errfile
echo "" > $mailfile

for ctx in $(ls /proc/virtual/|grep -v info|grep -v status)
do
vm=$(grep $ctx /etc/vservers/*/context|cut -d'/' -f 4)

        echo "Working on VM $vm :" >> $mailfile
        echo "Checking for collation..." >> $mailfile
        MYSQL_COMMAND="vserver $vm exec mysql"
        DATABASES=$($MYSQL_COMMAND -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$)

	ERRCODE=0
        for db in $DATABASES
        do

                RESULT=$($MYSQL_COMMAND -t -e "use $db; SELECT table_schema,table_name,Engine,table_collation FROM information_schema.tables WHERE table_schema = DATABASE() AND table_collation <> 'utf8_bin'")
                if [[ $RESULT != "" ]]
                then
                         $MYSQL_COMMAND -t -e "use $db; SELECT table_schema,table_name,Engine,table_collation FROM information_schema.tables WHERE table_schema = DATABASE() AND table_collation <> 'utf8_bin'" >> $mailfile
ERRCODE=1
                fi
        done
        if [[ $ERRCODE == 0 ]]
        then
                echo "...OK!" >> $mailfile
        fi

echo "Checking for spam..." >> $mailfile
ERRCODE=0

        for db in $DATABASES
        do
                CHECK_COMMANDS=$($MYSQL_COMMAND -t -e "use $db; select count(XWO_NAME) as coms,XWO_NAME as doc from xwikiobjects where XWO_CLASSNAME='XWiki.XWikiComments' GROUP BY XWO_NAME HAVING coms >= $nbcoms;")
                if [[ $CHECK_COMMANDS != "" ]]
                then
                        echo "We have found more than $nbcoms comments in database *** $db *** :" >> $mailfile
                        $MYSQL_COMMAND -t -e "use $db; select count(XWO_NAME) as coms,XWO_NAME as doc from xwikiobjects where XWO_CLASSNAME='XWiki.XWikiComments' GROUP BY XWO_NAME HAVING coms >= $nbcoms;" >> $mailfile
                        ERRCODE=1
                        echo "" >> $mailfile
                fi
        done

if [[ $ERRCODE == 0 ]]
         then
                echo "...OK!" >> $mailfile
         fi

echo "" >> $mailfile
echo "~~~~~~~~~~~~~~" >> $mailfile
echo "" >> $mailfile

done

## Appending errors at the end of the mail
echo " ############  Errors of the script, below ###########" >> $mailfile
cat $errfile >> $mailfile
#

## Sending the mail and deleting the log file
cat $mailfile | mail -s "Spam/collation report for $(hostname) machine" $mail_add

if [[ $? == 0 ]]
then
rm $mailfile
fi
#
