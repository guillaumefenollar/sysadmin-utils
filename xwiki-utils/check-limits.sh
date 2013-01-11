#!/bin/bash
# This is a script to set the limit of max open files by the system, at a higher value. This is useful for huge wikis.
#
# Things to check here
# 1 - /etc/pam.d/common-session must include "session required pam_limits.so"
# 2 - /etc/security/limits.conf must include
#	*	-	nofile	7168
#	root	-	nofile	7168
# 3 - /etc/pam.d/su AND /etc/pam.d/sudo MUST BOTH contain:
#	@include common-session

nofile=7168 ## value of max open files to set

# 2 equals not set yet. 1 will be false, 0 will be true
has_pam_limits=2
has_limits_root_set=2
has_limits_all_set=2
has_common_session_su=2
has_common_session_sudo=2

## 1 ##

/bin/grep -e '^session.*required.*pam_limits\.so$' /etc/pam.d/common-session &>/dev/null
has_pam_limits=$?
if test $has_pam_limits == 1 ; then
	echo "session required pam_limits.so" >> /etc/pam.d/common-session
	echo "Pam_limits.so has been added to /etc/pam.d/common-session file"
fi

## 2 ##

# Retrieving the value set, if it's already set in limits.conf. If it's not present, add the line. If the line is present with a different value, replace it to $nofile only if the value found is lower.
line_limits_root_set=$(/bin/grep -e '^root.*-.*nofile.*' /etc/security/limits.conf)
has_limits_root_set=$?
if test $has_limits_root_set == 0 ; then
	value_limits_root_set=$(echo $line_limits_root_set|awk '{print $NF}')
	if test $value_limits_root_set -lt $nofile ; then
		sed -i "s/$value_limits_root_set/$nofile/g" /etc/security/limits.conf
	fi
elif test $has_limits_root_set == 1 ; then
	echo "root	-	nofile	$nofile" >> /etc/security/limits.conf
	echo "limits for open files for root has been set to $nofile"
fi

# Same for line '* -	nofile $nofile'
line_limits_all_set=$(/bin/grep -e '^\*.*-.*nofile.*' /etc/security/limits.conf)
has_limits_all_set=$?
if test $has_limits_all_set == 0 ; then
        value_limits_all_set=$(echo $line_limits_all_set|awk '{print $NF}')
        if test $value_limits_all_set -lt $nofile ; then
                sed -i "s/$value_limits_all_set/$nofile/g" /etc/security/limits.conf
        fi
elif test $has_limits_all_set == 1 ; then
        echo "*	-	nofile  $nofile" >> /etc/security/limits.conf
        echo "limits for open files for All has been set to $nofile"
fi

## 3 ##

/bin/grep -e '^@include.*common-session$' /etc/pam.d/su &>/dev/null
has_common_session_su=$?
if test $has_common_session_su == 1 ; then
	echo "@include common-session" >> /etc/pam.d/su
	echo "include of common-session has been added to /etc/pam.d/su"
fi
/bin/grep -e '^session.*required.*pam_limits\.so$' /etc/pam.d/sudo &>/dev/null
has_pam_limits_sudo=$?
if test $has_pam_limits_sudo == 1 ; then
	echo "session required pam_limits.so" >> /etc/pam.d/sudo
	echo "Adding pam_limits.so to /etc/pam.d/sudo"
fi

echo "" > $0.flag
