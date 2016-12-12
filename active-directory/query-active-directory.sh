#!/bin/bash

if [[ $(which ldapsearch) == "" ]]; then echo "Ldapsearch is needed as a dependency, please install it" ; exit 1 ; fi

if [[ $1 == "" ]];
then
    echo "Usage: $0 <ldap query>"
    echo "Example: $0 sAMAccountName=testuser"
fi
ldapsearch -x -LLL -D "<username>" -H <server> -b "<basedn>" -w '<password>' -s sub "($1)"
