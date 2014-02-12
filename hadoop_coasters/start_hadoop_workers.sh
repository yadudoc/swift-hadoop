#!/bin/bash


############# Settings ################
#Input data dir on hdfs to start workers
INPUT_DIR="/user/ybabuji/fake"
#Remote setup script
REMOTE_SCRIPT=./install_nltk.sh
#Port for python webserver
PUBLISH_PORT=$(( 55000 + $(($RANDOM % 1000)) ))
#Port used by workers to connect back to coaster service
WORKER_PORT=$(( 50000 + $(($RANDOM % 1000 )) ))
#Port used by swift to talk to the coaster service
SERVICE_PORT=50005
#IP of headnode
HEADNODE="http://128.135.159.52"
#Worker walltime in minutes
WALLTIME=240
#Output from scripts on HDFS
OUTPUT=/user/$USER/results
#######################################

perror(){
    echo "$*"
    exit -1;
}

cleanup(){
    # Cleanup previous instances and unnecessary files
    rm -rf test-2014*
    rm -rf driver* *~

    echo "Killing previous java services"
    killall -u $USER java -9
}

init_coaster_service(){
    echo "Starting new coaster-service"
    coaster-service -p $SERVICE_PORT -localport $WORKER_PORT -nosec -passive &> coaster-service.logs &

cat <<EOF > sites.xml
<?xml version="1.0" encoding="UTF-8"?>
<config xmlns="http://www.ci.uchicago.edu/swift/SwiftSites">
  <pool handle="persistent-coasters">
    <execution provider="coaster-persistent" url="$HEADNODE:$SERVICE_PORT" jobmanager="local:local"/>
    <profile namespace="globus" key="workerManager">passive</profile>
    <profile namespace="globus" key="jobsPerNode">4</profile>
    <!--<profile key="jobThrottle" namespace="karajan">100</profile>-->
    <profile namespace="karajan" key="initialScore">10000</profile>
    <profile namespace="globus" key="maxwalltime">04:00:00</profile>
    <profile namespace="karajan" key="jobThrottle">8.10</profile>
    <filesystem provider="local" url="none" />
    <workdirectory>/home/$USER/swiftwork</workdirectory>
  </pool>

  <pool handle="local1">
    <workdirectory>/tmp/$USER/swiftwork</workdirectory>
    <profile namespace="karajan" key="initialScore">10000</profile>
    <execution provider="coaster" jobmanager="local:local"/>
    <filesystem provider="local"/>
    <workdirectory>/home/$USER/swiftwork</workdirectory>
  </pool>
</config>

EOF
}

# Start the python webserver to serve nltk files
echo "Starting python web-server on $HEADNODE:$PUBLISH_PORT"
python -m SimpleHTTPServer $PUBLISH_PORT &> pyserver.log &
sleep 1 # Delay to ensure the errors are in the log
grep "socket.error" pyserver.log
[ "$?" == "0" ] && perror "Python webserver failed to start"


cleanup
init_coaster_service

cat $REMOTE_SCRIPT > remote_script.sh
echo -e "\n./worker.pl $HEADNODE:$WORKER_PORT 0099 ~/user/$USER/workerlog -w $WALLTIME\n" >> remote_script.sh
chmod a+x remote_script.sh

echo "Removing $OUTPUT"
hadoop dfs -rmr $OUTPUT


# Workers are submitted as map jobs to hadoop
# The timeout is in milliseconds.
# Files needed for remote execution are passed along
# using the -file option
# -cmdenv allows you to set environment variables
echo "Starting hadoop jobs"
hadoop jar /opt/hadoop-0.20.203.0/contrib/streaming/hadoop-streaming-0.20.203.0.jar \
    -D mapred.task.timeout=$(($WALLTIME*60000)) \
    -input  $INPUT_DIR \
    -output $OUTPUT \
    -cmdenv PYTHONPATH=/tmp/python-libs/lib/python/ \
    -cmdenv NLTK_DATA=/tmp/python-libs/lib/python/data \
    -file ./remote_script.sh \
    -file ./worker.pl \
    -mapper "./remote_script.sh $HEADNODE:$PUBLISH_PORT"

echo "Removing results directory"
rm -rf ./results &> /dev/null

echo "Copying $OUTPUT from hdfs"
hadoop dfs -copyToLocal $OUTPUT ./
