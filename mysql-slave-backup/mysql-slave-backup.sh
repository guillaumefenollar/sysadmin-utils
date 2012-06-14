#!/bin/bash 

# Version 1.0 - 2012/05/31

## This script makes a backup (via rsync) of a Slave MySQL files, to permit a restore in case of slave failure or disaster.

MAIL_ADDR=guillaume.fenollar@xwiki.com,alex@xwiki.com
#MAIL_ADDR=guillaume.fenollar@xwiki.com,alex@xwiki.com
DEST="/home/mysql-slave-backup/vservers/"    ## Where to put the files
MAIL_TO_SEND=/var/log/mysql-slave-backup.mail ## Temporary mail place

## List of running vservers
VSERVERS_LIST=$(for i in $(/usr/sbin/vserver-stat|awk '{print $1}'|grep -v CTX); do grep $i /etc/vservers/*/context|cut -d'/' -f 4; done)
#VSERVERS_LIST=vdbrepl_vwaterwiki-prod

for i in $VSERVERS_LIST
do

LOG_FILE=/home/mysql-slave-backup/logs/$i.log  ## Where to write the logs (Into Vservers)
STATUS_FILE=/home/mysql-slave-backup/logs/$i.status  ## Where to write a global status (Into Vservers)
DIRS="var/lib/mysql/ var/log/mysql/ etc/mysql/"   ## What directories to backup (Into Vservers)
cd /home/pub/vservers/$i

if [[ ! -d /home/mysql-slave-backup/vservers/$i ]]
then
	mkdir -p /home/mysql-slave-backup/vservers/$i
fi

echo "10-The script has stopped unexpectedly" > $STATUS_FILE
echo "Backup started at $(date %T)" > $LOG_FILE

### Stop slave

if [[ $(/usr/sbin/vserver $i exec mysql -u root -e "show slave status\G"|grep Running|grep Yes|wc -l) == 2 ]]
then
	/usr/sbin/vserver $i exec mysql -e "stop slave;"
	sleep 2

	if [[ $(/usr/sbin/vserver $i exec mysql -u root -e "show slave status\G"|grep Running|grep No|wc -l) == 2 ]]
	then
		echo "#### STEP 1 # Replication slave has been stopped. ####" >> $LOG_FILE
	else
		echo "Slaves haven't been stopped for an unknown reason." >> $LOG_FILE
		echo "2-Error during the slave stop" > $STATUS_FILE
		continue
	fi
else
	echo "1-Replication was not running at the launch of the script! Aborting..." > $STATUS_FILE
	continue
fi

### Rsync & start slave

echo "#### STEP 2 # Starting the backup ####" >> $LOG_FILE
rsync -R -avz --numeric-ids --delete $DIRS $DEST/$i/ 2>&1 >> $LOG_FILE

if [[ $? != "0" ]]
then
	echo "3-A problem during the transfer has been detected. Please check the log file." > $STATUS_FILE
	continue
else
	echo "SUCCESS" > $STATUS_FILE

	echo "#### STEP 3 # Trying to start the slave and checking that everything's alright" >> $LOG_FILE
	/usr/sbin/vserver $i exec mysql -e "start slave;"
	echo "Starting slave..." >> $LOG_FILE
	sleep 6

	if [[ $(/usr/sbin/vserver $i exec mysql -u root -e "show slave status\G"|grep Running|grep Yes|wc -l) == 2 ]]
	then
		echo "#### The replication slave has started successfully! ####" >> $LOG_FILE
		echo "0-The operation finished successfully, slave is running" > $STATUS_FILE
                continue
	else
		echo "A problem occured during the replication start" >> $LOG_FILE
		echo "Here the reported error : " >> $LOG_FILE
		/usr/sbin/vserver $i exec mysql -e "show slave status\G"|grep Last_IO_Error >> $LOG_FILE
		echo "4-Replication did not start successfully" > $STATUS_FILE
		continue
	fi
fi

done

### Mail

ERRCODE=0
echo "Here the report of the slave's backup script in date of $(date +%x)" > $MAIL_TO_SEND
echo "His goal is to make a backup once a day, on each running replication VM, you can see below the status for each of them :" >> $MAIL_TO_SEND
echo "" >> $MAIL_TO_SEND
echo "" >> $MAIL_TO_SEND

for i in $VSERVERS_LIST
do
    STATUS_FILE=/home/mysql-slave-backup/logs/$i.status
	if [[ $(cat $STATUS_FILE|cut -f1 -d'-') != 0 ]]
	then
		REPORT=$(cat $STATUS_FILE|cut -f2 -d'-')
		echo "~ $i - $REPORT" >> $MAIL_TO_SEND
		ERRCODE=1
	fi

done

if [[ $ERRCODE == 0 ]]
then
	mail -s "Backup Slave Report - OK" $MAIL_ADDR < $MAIL_TO_SEND
else
	mail -s "Backup Slave Report - ERROR" $MAIL_ADDR < $MAIL_TO_SEND
fi
