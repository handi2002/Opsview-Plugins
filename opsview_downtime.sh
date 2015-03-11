#!/bin/bash
#
# create or delete downtime for a single host using opsview curl rest api
  
CURL=/usr/bin/curl
OPSVIEW_HOSTNAME="youropsview.com"
USERNAME=admin
URL="/rest/downtime"
hours_of_downtime=2
  
usage()
{
    echo "Usage: $0 -p <opsview apiuser password> -h <host> [-g <group>] -c (create|delete) [-t <hours_of_downtime>]"
    exit 1
}
  
while getopts p:h:g:t:c: opt
do
    case $opt in
      p) password=$OPTARG;;
      h) host=$OPTARG;;
      g) group=$OPTARG;;
      t) hours_of_downtime=$OPTARG;;
      c) command=$OPTARG;;
      \?) usage;;
    esac
done
  
  
if [ "x$password" = "x" ] || [ "x$command" = "x" ]
then
    usage
fi
  
# LOGIN
  
token_response=`$CURL -k -s -H 'Content-Type: application/json' https://$OPSVIEW_HOSTNAME/rest/login -d "{\"username\":\"$USERNAME\",\"password\":\"$password\"}"`
token=`echo $token_response | cut -d: -f 2 | tr -d '"{}'`
if [ ${#token} -ne 40 ]
then
    echo "$0: Invalid apiuser login. Unable to $command downtime."
    exit 1
fi
  
  
if [ "$command" = "create" ]
then
    starttime=`date +"%Y/%m/%d %H:%M:%S"`
    endtime=`date +"%Y/%m/%d %H:%M:%S" -d "$hours_of_downtime hours"`
    comment="$0 api call"
    data="{\"starttime\":\"$starttime\",\"endtime\":\"$endtime\",\"comment\":\"$comment\"}"

   if [ "x$host" != "x" ]
    then
    # create downtime on host- POST
    result=`$CURL -k -s -H "Content-Type: application/json" -H "X-Opsview-Username: $USERNAME" -H "X-Opsview-Token: $token" https://$OPSVIEW_HOSTNAME$URL?host=$host -d "$data"`
    exit_status=$?
    else
    # create downtime on host group - POST
    result=`$CURL -k -s -H "Content-Type: application/json" -H "X-Opsview-Username: $USERNAME" -H "X-Opsview-Token: $token" https://$OPSVIEW_HOSTNAME$URL?hostgroupname=$group -d "$data"`
    exit_status=$?    
   fi
else
    # delete downtime - DELETE
    params="host=$host"
    result=`$CURL -k -s -H "Content-Type: application/json" -H "X-Opsview-Username: $USERNAME" -H "X-Opsview-Token: $token" -X DELETE https://$OPSVIEW_HOSTNAME$URL?$params`
    exit_status=$?
fi
if [ "x$host" != "x" ]
  then
echo "$result" | grep $host > /dev/null
host_in_output=$?
  else
echo "$result" | grep $group > /dev/null
host_in_output=0
fi    
if [ "$exit_status" -ne "0" ] || [ "$host_in_output" -ne "0" ]
then
  echo "Unable to $command downtime for $host.  Result of call:"
  echo $result
  exit 1
fi