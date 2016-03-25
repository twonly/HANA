#!/bin/sh

#Grant hdbroles to massive users
#Author: Jiongyu Yu
#Date: 2016-03-25

LogFile="./grant.log"
Usage() {
        echo -e "------------------------------------------------------------------------"
        echo -e "HANA Role Grant"
        echo -e "  Please maintian the user list in a file"
        echo -e "  HDBUSERSTORE KEY should be maintian before execution (with sufficient privileges). KEY: GRANTROLE"
        echo -e "------------------------------------------------------------------------"
        echo -e "|USAGE: $0 [Options]"
        echo -e "|\t-f | --file\t\tUser List File"
        echo -e "|\t-h | --help\t\tPrint help info\n|"
        echo -e "|\tExample usage:\t\t$0 -f ./UserList.txt"
        echo -e "------------------------------------------------------------------------"
        exit 1
}

#Get parameters
PARAM=$(getopt -o f:h --long file:,help -- "$@" 2>/dev/null)
[ $? != 0 ] && Usage
eval set -- "$PARAM"
while true ; do
  case "$1" in
    -f|--file)
      filename=$2; shift 2;;
    -h|--help)
      Usage ; shift ;;
    --)
      shift; break;;
  esac
done
#echo "FILENAME: $filename"
if [ "x$filename" = "x" ]; then
    echo "Error: filename not specified"
    exit 2
fi
# Check file existence
if [ ! -f $filename ]; then
  echo "Error: File $filename not exist"
  exit 2
fi

#-----------------------------------------------------------------------#
# Check execution user
#-----------------------------------------------------------------------#
if [ "x$SAPSYSTEMNAME" = "x" ]; then
    typeset usr=$(whoami)
    if expr match ${usr} "[a-z][a-z0-9][a-z0-9]adm" != 6 >/dev/null ; then
      echo "TableExport.sh: This script requires <sid>adm user, but got '${usr}'"
      exit 2
    fi
fi

HDBUSERSTORE="GRANTROLE"
RES=`hdbsql -U $HDBUSERSTORE -a -x "select * from dummy"`
if [ $? != 0 ]; then
  echo -e "Error when using hdbuserstore key $HDBUSERSTORE"
  exit 2
fi

#Process
if [-f $LogFile]; then
  rm $LogFile
fi
echo "Info: Start granting roles..."
while read line #read user list
do
  RES=$(hdbsql -U $HDBUSERSTORE -a -x "call GRANT_ACTIVATED_ROLE ('developer::role_to_grant', '${line}')" 2>> $LogFile)
done < $filename
echo "Info: End granting roles..."
echo "Info: Logs written to $LogFile"
