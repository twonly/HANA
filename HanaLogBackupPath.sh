#!/bin/sh

user=($(awk -F: '$5=="SAP HANA Database System Administrator" {printf "%-3s\n", $1}' /etc/passwd))
#echo ${user[1]}
for i in "${user[@]}"
do
  SID=`echo ${i:0:3} | tr [a-z] [A-Z]`
  #echo $SID
  confFile="/usr/sap/$SID/SYS/global/hdb/custom/config/global.ini"
  #echo $confFile
  grep -i basepath_logbackup $confFile
done
