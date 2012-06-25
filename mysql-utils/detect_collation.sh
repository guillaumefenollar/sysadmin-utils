#!/bin/bash

MYSQL_COMMAND=mysql

DATABASES=$(mysql -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$)

for db in $DATABASES
do
$MYSQL_COMMAND -e "use $db; SELECT table_schema,table_name,Engine,table_collation FROM information_schema.tables WHERE table_schema = DATABASE() AND table_collation <> 'utf8_bin'"
done




################
###############   - VSERVER UNDER  -    #########
################




#!/bin/bash

for vm in $(ls -1 /etc/vservers/|grep -v newvserver|grep -v ip.list)
do
        echo "Checking VM $vm...     ########################################################################### "
        MYSQL_COMMAND="vserver $vm exec mysql"
        DATABASES=$($MYSQL_COMMAND -N -s -r -e 'show databases'|grep -v ^information_schema$|grep -v ^mysql$)
        for db in $DATABASES
        do
          $MYSQL_COMMAND -e "use $db; SELECT table_schema,table_name,Engine,table_collation FROM information_schema.tables WHERE table_schema = DATABASE() AND table_collation <> 'utf8_bin'"
        done
        echo ""
done

