#!/bin/bash

### LOCAL MACHINE

pid=$(pgrep -f 'puppet\ agent')

if [[ $(echo $pid|wc -w) > 1 ]]
then
        /bin/echo "There is more than 1 process running for puppet on machine `hostname` . Killing them all..."
        if [[ $1 != "--test" ]]
        then
        for p in $pid
        do
               /bin/kill $p
        done
        pid=""
        fi
fi

#If puppetd doesn't run or if the pid retrieved isn't the same as in agent.pid file
if [[ "$pid" == "" || "$(grep $pid /var/run/puppet/agent.pid)" == "" ]]
then
        /bin/echo "Puppet was not running on machine `hostname`, trying to start it..."
        if [[ $1 != "--test" ]]
        then
                /usr/bin/killall puppet 1>/dev/null
                /usr/bin/killall puppetd 1>/dev/null
                /usr/sbin/puppetd
        fi
fi



### VSERVERS VMs
if [[ -x `which vserver 2>/dev/null` ]]; then

vserver_bin="$(which vserver)"

#For each vserver running, we use the context number
for ctx in $(ls /proc/virtual/|grep -v info|grep -v status)
do
#Retrieving name of vserver
vm=$(grep -l $ctx /etc/vservers/*/context|cut -d'/' -f 4)

#checking if puppet runs right now
pid="$(/${vserver_bin} $vm exec pgrep -f 'puppet\ agent')"

if [[ $(echo $pid|wc -w) > 1 ]]
then
        /bin/echo "There is more than 1 process running for puppet in $vm. Killing them all..."
        if [[ $1 != "--test" ]]
        then
        for p in $pid
        do
                /${vserver_bin} $vm exec kill $p
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
                /${vserver_bin} $vm exec /usr/bin/killall puppet 1>/dev/null
                /${vserver_bin} $vm exec /usr/bin/killall puppetd 1>/dev/null
                /${vserver_bin} $vm exec /usr/sbin/puppetd
        fi
fi

done

fi

### OpenVZ VMs
if [[ -x `which vzlist 2>/dev/null` ]]; then

ctid_all=$(vzlist --all | grep -v "CTID" | awk '{print $1}')
for ctid in $ctid_all
do
pid="$(/usr/sbin/vzctl exec $ctid pgrep -f 'puppet\ agent')"

if [[ $(echo $pid|wc -w) > 1 ]]
then
        /bin/echo "There is more than 1 process running for puppet in $vm. Killing them all..."
        if [[ $1 != "--test" ]]
        then
        for p in $pid
        do
                /usr/sbin/vzctl exec $ctid kill $p
        done
        pid=""
        fi
fi

VE_PRIVATE="`grep VE_PRIVATE /etc/vz/conf/${ctid}.conf | grep -v "#" | cut -d "=" -f 2 | cut -d '"' -f 2 | sed 's/$VEID//g'`"

#If puppetd doesn't run or if the pid retrieved isn't the same as in agent.pid file
if [[ "$pid" == "" || "$(grep $pid ${VE_PRIVATE}$ctid/var/run/puppet/agent.pid)" == "" ]]
then
        /bin/echo "Puppet was not running on OpenVZ VM of context $ctid, hosted by `hostname`, trying to start it..."
        if [[ $1 != "--test" ]]
        then
                /usr/sbin/vzctl exec $ctid /usr/bin/killall puppet 1>/dev/null
                /usr/sbin/vzctl exec $ctid /usr/bin/killall puppetd 1>/dev/null
                /usr/sbin/vzctl exec $ctid /usr/sbin/puppetd
        fi
fi
done
fi
