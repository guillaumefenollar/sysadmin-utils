#!/bin/bash
# THE SCRIPT EXITS IF ANY COMMANDS RETURNS ANYTHING ELSE THAN 0
set -e
#
if [[ $UID != "0" ]]; then
        echo "Warning: This scripts needs to run as root !"
        # We let it continue since it could still be run with sudo instead
fi
echo "Warning, this script will :"
echo "- Rescan blocks"
echo "- Resize map"
echo "- Resize PV"
echo "Any error in the process will make it stop to avoid nasty things to happen as much as possible."
echo ""
echo -n "Please enter the name of LUN to extend : "
read LUN
if [[ ! -h /dev/mapper/$LUN ]]; then
        echo "The LUN $LUN doesn't seems valid! Aborting..."
        exit 1
fi
PATHS=$(/sbin/multipath -ll|grep -A11 "$LUN "|grep "active ready running"|grep -Eo ' sd\w+ '|tr -d " ")
if [[ $(echo "$PATHS"|wc -w) != 8 && $(echo "$PATHS"|wc -w) != 4 ]];then
        echo "The following paths don't seem valid :"
        echo $PATHS
        exit 1
fi
# Storing size of LUN before resize for reporting
SIZE_1=$(/sbin/multipath -ll|grep -A1 "$LUN "|grep '^size='|cut -f1 -d' ')
# Doing tests to ensure everything's fine
for p in $PATHS; do
        if [[ ! -b /dev/$p ]];then
                echo "$p is not a block, aborting..."
                exit 1
        fi
done
# Rescan blocks
echo -n "Rescaning blocks ..."
for p in $PATHS; do
        echo "1">/sys/block/$p/device/rescan
done
echo "OK"
# Resize map
echo -n "Resizing map ..."
echo "resize map $LUN" | /sbin/multipathd -k 1>/dev/null
echo "OK"
# PVresize
echo -n "Resizing PV ..."
pvresize /dev/mapper/$LUN 1>/dev/null
echo "OK"
SIZE_2=$(/sbin/multipath -ll|grep -A1 "$LUN "|grep '^size='|cut -f1 -d' ')
if [[ "$SIZE_1" == "$SIZE_2" ]]; then
        echo "Resize did not change LUN size, something may be wrong. ($SIZE_2)"
else
        echo "LUN $LUN was extended from $SIZE_1 to $SIZE_2"
fi
