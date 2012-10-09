#!/bin/bash
# This script help to create activity stream index which is missing in XWiki version <4.2
##CONFIG##
mysql_cmd="mysql -u root"
##

AS_INDEX="$($mysql_cmd -N -s -e 'use xwiki; show index from activitystream_events;'|grep ase_requestid)"

if [[ $AS_INDEX == "" ]]
then
	$mysql_cmd -N -s -e 'ALTER TABLE `xwiki`.`activitystream_events` ADD INDEX `EVENT_REQUEST`(`ase_requestid`);'
else
	echo "activitystream_events for ase_requestid is already there"
fi
