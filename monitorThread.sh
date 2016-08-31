#!/bin/sh

LogFile="./activation.log"

#-----------------------------------------------------------------------#
# Check execution user
#-----------------------------------------------------------------------#
if [ "x$SAPSYSTEMNAME" = "x" ]; then
    typeset usr=$(whoami)
    if expr match ${usr} "[a-z][a-z0-9][a-z0-9]adm" != 6 >/dev/null ; then
      echo "monitorThreads.sh: This script requires <sid>adm user, but got '${usr}'"
      exit 2
    fi
fi

HDBUSERSTORE="GRANTROLE"
RES=`hdbsql -U $HDBUSERSTORE -a -x "select * from dummy"`
if [ $? != 0 ]; then
  echo -e "Error when using hdbuserstore key $HDBUSERSTORE"
  exit 2
fi

#Check log file 
#if [ -f $LogFile ]; then
#  rm $LogFile
#fi

old_user=""
old_duration=0

echo "Info: Start monitoring activation threads..."

while true
do
  echo "====================="
  RES=$(hdbsql -U $HDBUSERSTORE -a -x "select USER_NAME, APPLICATION_USER_NAME, DURATION from M_SERVICE_THREADS where service_name='indexserver' and thread_state='Running' and thread_detail like '%call SYS.REPOSITORY_REST%'")
  #RES=$(hdbsql -U $HDBUSERSTORE -a -x "select USER_NAME, APPLICATION_USER_NAME, DURATION from M_SERVICE_THREADS where service_name='indexserver' and thread_state='Running'")
  #echo "$RES"
  if [ "x$RES" = "x" ]; then 
    echo "No activation running"
    if [[ "x$old_user"!="x" && $old_duration -gt 2400000 ]]; then
	echo "$(date) $old_user, $old_duration" >> $LogFile
	echo "Identified: $old_user, $old_duration"
	old_user=""
	old_duration=0
    fi
    old_user=""
    old_duration=0
  else
	OIFS=$IFS
	IFS=' '
	read -r -a arr <<< "${RES}"

	for var in ${arr[@]}; do
	  #echo $var
	  IFS=','
	  read user app_user duration <<< "$var"

	  echo "USER: $user, Duration: $duration"
	  
	  if [[ $user != $old_user && $old_duration -gt 2400000 ]]; then
	    #Activation Finished, user changed
	    #Duration more than 1000 seconds
	    #write result to text file
	    echo "$(date) $old_user, $old_duration" >> $LogFile
	    echo "Identified: $old_user, $old_duration"
	    old_user=""
	    old_duration=0
	  elif [[ $user == $old_user && $duration -lt $old_duration && $old_duration -gt 2400000 ]]; then
	    echo "$(date) $old_user, $old_duration" >> $LogFile
	    echo "Identified: $old_user, $old_duration"
	    old_user=""
	    old_duration=0
	  else
	    echo "No satified: $old_user, $old_duration"
	    old_user=$user
	    old_duration=$duration
	  fi
	done

	IFS=$OIFS
  fi
    
  sleep 5
done
echo "Info: End monitoring..."
echo "Info: Logs written to $LogFile"
