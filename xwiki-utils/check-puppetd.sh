#!/bin/bash

#For each vserver running, we use the context number
for ctx in $(ls /proc/virtual/|grep -v info|grep -v status)
do
#Retrieving name of vserver
vm=$(grep -l $ctx /etc/vservers/*/context|cut -d'/' -f 4)

#checking if puppet runs right now
pid="$(/usr/sbin/vserver $vm exec pgrep puppet)"

if [[ $(echo $pid|wc -w) > 1 ]]
then
        /bin/echo "There is more than 1 process running for puppet in $vm. Killing them all..."
        if [[ $1 != "--test" ]]
        then
        for p in $pid
        do
                /usr/sbin/vserver $vm exec kill $p
        done
        pid=""
        fi
fi

#If puppetd doesn't run or if the pid retrieved isn't the same as in agent.pid file
if [[ "$pid" == "" || "$(grep $pid /etc/vservers/$vm/vdir/var/run/puppet/agent.pid)" == "" ]]
then
        /bin/echo "Puppet was not running on VM $vm, hosted by `hostname`, trying to start it..."
        if [[ $1 != "--test" ]]
        then
                /usr/sbin/vserver $vm exec /usr/bin/killall puppet 1>/dev/null
                /usr/sbin/vserver $vm exec /usr/bin/killall puppetd 1>/dev/null
                /usr/sbin/vserver $vm exec /usr/sbin/puppetd
        fi
fi

done
