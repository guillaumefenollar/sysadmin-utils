#!/bin/bash

## Script to extract the MySQL indexes names and inject them in another database
src_database=xwiki
# Uncomment and configure below to avoid prompt
# dst_database=
mysql_cmd="mysql -uroot --password="

$mysql_cmd -NBe "SELECT index_name, table_name, column_name, sub_part FROM information_schema.statistics WHERE index_name != 'primary' and table_schema = \"$src_database\";" > $0.tmp

echo "The following indexes are found in the database $src_database :"
echo ""

trap "rm $0.tmp $0-indexes.tmp" SIGINT SIGQUIT SIGTERM TERM

while read line
do
  read ind tbl col len <<<$(echo $line)
  if [[ ! $len -gt 10 ]];then
	len=""
  else
	len="($len)"
  fi
  echo "create index $ind on $tbl (${col}${len});"|tee -a $0-indexes.tmp
  
done < $0.tmp

echo
echo

while [[ $dst_database == "" ]];do
  echo "On what database do you want to create all those indexes ?"
  read dst_database
done

$mysql_cmd $dst_database < $0-indexes.tmp

trap SIGINT SIGQUIT SIGTERM TERM
echo
echo "Finished, please see above for errors."
echo "Cleaning..."

rm $0.tmp $0-indexes.tmp
