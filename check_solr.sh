#!/bin/bash
#
# opsview plugin to check solr cloud server status
# add comments
  
CURL=/usr/bin/curl
exitcode=0
  
usage()
{
    echo "Usage: $0 -h <host> -c <corename> -o (heap|response|numdocs|updates)"
    exit 1
}
  
while getopts h:c:o: opt
do
    case $opt in     
      h) host=$OPTARG;;
      c) core=$OPTARG;;
      o) option=$OPTARG;;
      \?) usage;;
    esac
done
  
  
if [ "x$host" = "x" ] || [ "x$core" = "x" ] || [ "x$option" = "x" ]
then
    usage
fi
  


if [ "$option" = "numdocs" ]; then
  $CURL --connect-timeout 3 "http://$host:8983/solr/$core/admin/mbeans?stats=true&cat=CORE&key=searcher&key=stats" > /tmp/$$.tmp 2>&1
  if [ $? = 0 ]; then
    numdocs=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"numDocs\">\(.*\)<\/int><int\ name=\"maxDoc\".*/\1/g"`
    warmuptime=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"warmupTime\">\(.*\)<\/long><\/lst>.*/\1/g"`
    rm /tmp/$$.tmp
     if [ "x$numdocs" != "x" ]; then
       echo "OK - numdocs: $numdocs warmupTime: $warmuptime | numDocs=${numdocs};;;; warmupTime=${warmuptime};;;; "
       exitcode=0
     else
        echo "Critical - can not get info from $core"
       exitcode=2 
     fi 
  else
    echo "Critical - can not get info from $core"
    exitcode=2  
  fi 
elif [ "$option" = "updates" ]; then
  $CURL --connect-timeout 3 "http://$host:8983/solr/$core/admin/mbeans?stats=true&CAT=UPDATEHANDLER&key=updateHandler" > /tmp/$$.tmp 2>&1
  if [ $? = 0 ]; then
    cumulative_adds=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"cumulative_adds\">\(.*\)<\/long><long\ name=\"cumulative_deletesById\".*/\1/g"`
    adds=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"adds\">\(.*\)<\/long><long\ name=\"deletesById\".*/\1/g"`
    commits=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"commits\">\(.*\)<\/long><str\ name=\"autocommit\ maxTime\".*/\1/g"`
    rm /tmp/$$.tmp
    echo "OK - cumulative_adds: $cumulative_adds, adds: $adds, commits: $commits |cumulative_adds=${cumulative_adds};;;; adds=${adds};;;; commits=${commits};;;; "
    exitcode=0
  else
    echo "Critical - can not get info from $core"
    exitcode=2     
  fi 

elif [ "$option" = "response" ]; then
  $CURL --connect-timeout 3 "http://$host:8983/solr/$core/admin/mbeans?stats=true&CAT=QUERYHANDLER&key=/update" > /tmp/$$.tmp 2>&1
  if [ $? = 0 ]; then
    avgRequestsPerSecond=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"avgRequestsPerSecond\">\(.*\)<\/double><double\ name=\"5minRateReqsPerSecond\".*/\1/g"|cut -c1-6`
    avgTimePerRequest=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"avgTimePerRequest\">\(.*\)<\/double><double\ name=\"medianRequestTime\".*/\1/g"|cut -c1-6`
    minRateReqsPerSecond=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"5minRateReqsPerSecond\">\(.*\)<\/double><double\ name=\"15minRateReqsPerSecond\".*/\1/g"|cut -c1-6`
    rm /tmp/$$.tmp
    echo "OK - avgRequestsPerSecond: $avgRequestsPerSecond, avgTimePerRequest: $avgTimePerRequest, 5minRateReqsPerSecond=$minRateReqsPerSecond|avgRequestsPerSecond=${avgRequestsPerSecond};;;; avgTimePerRequest=${avgTimePerRequest};;;; 5minRateReqsPerSecond=${minRateReqsPerSecond};;;; "
    exitcode=0
  else
    echo "Critical - can not get info from $core"
    exitcode=2  
  fi

elif [ "$option" = "heap" ]; then
  $CURL --connect-timeout 3 "http://$host:8983/solr/$core/admin/system" > /tmp/$$.tmp 2>&1
  if [ $? = 0 ]; then
  heap=`cat /tmp/$$.tmp | grep responseHeader | sed "s/.*\"used%\">\(.*\)<\/double><\/lst>.*/\1/g"|cut -c1-5`
  rm /tmp/$$.tmp
  echo "OK - heap usage:${heap}%| heapUsage=${heap}%;;;; "
  exitcode=0
  else
    echo "Critical - can not get info from $core"
    exitcode=2  
  fi  

else
   usage
fi 

exit $exitcode
