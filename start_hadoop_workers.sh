#!/bin/bash

###############################################################################
# Settings
###############################################################################
# Number of workers started by hadoop for swift
WORKER_COUNT=10
# Worker walltime in minutes
WALLTIME=240
# Remote setup script | or set to empty string
# REMOTE_SCRIPT=./install_nltk.sh
REMOTE_SCRIPT=""
# Input data dir on hdfs to start workers
INPUT_DIR="/user/$USER/tmp"
# IP of headnode
HEADNODE="http://128.135.159.52"
# Hadoop streaming jar
HADOOP_STREAMING="/opt/hadoop-0.20.203.0/contrib/streaming/hadoop-streaming-0.20.203.0.jar"
# Set to 1 to enable python webserver, 0 to disable.
ENABLE_PYTHON_WEBSERVER=0
# Port for python webserver
PUBLISH_PORT=$(( 55000 + $(($RANDOM % 1000))  ))
# Port used by workers to connect back to coaster service
WORKER_PORT=$((  50000 + $(($RANDOM % 1000 )) ))
# Port used by swift to talk to the coaster service
SERVICE_PORT=$(( 51000 + $(($RANDOM % 1000 )) ))
# Output from scripts on HDFS
OUTPUT=/user/$USER/results
###############################################################################

perror(){
    echo "$*"
    exit -1;
}

###############################################################################
# Cleanup previous instances and unnecessary files
rm -rf test-2014*
rm -rf driver* *~
echo "Killing previous java services"
killall -u $USER java -9
###############################################################################

###############################################################################
# Start the coaster service
###############################################################################
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
    <workdirectory>./swiftwork</workdirectory>
  </pool>

  <pool handle="local1">
    <profile namespace="karajan" key="initialScore">10000</profile>
    <execution provider="coaster" jobmanager="local:local"/>
    <profile namespace="globus" key="maxwalltime">02:00:00</profile>
    <filesystem provider="local"/>
    <workdirectory>/home/$USER/swiftwork</workdirectory>
  </pool>
</config>

EOF

sleep 2
CPS_LOG=$(ls -tr cps*log  | tail -n 1)
grep "Error starting coaster service" $CPS_LOG
if [[ "$?" == "0" ]]
then
    cat $CPS_LOG
    perror "Failed to start Coaster service"
fi

###############################################################################
# Start the python webserver to serve installation packages/files
###############################################################################
if [[ $ENABLE_PYTHON_WEBSERVER -eq 1 ]]
then
    echo "Starting python web-server on $HEADNODE:$PUBLISH_PORT"
    python -m SimpleHTTPServer $PUBLISH_PORT &> pyserver.log &
    sleep 1 # Delay to ensure the errors are in the log
    grep "socket.error" pyserver.log
    [ "$?" == "0" ] && perror "Python webserver failed to start"
fi
###############################################################################
# Setup remote worker script.
# If remote script is not provided include only the worker command
###############################################################################

if [[ -f "$REMOTE_SCRIPT" ]]
then
    echo "Using REMOTE_SCRIPT    : $REMOTE_SCRIPT"
    cat $REMOTE_SCRIPT    > remote_script.sh
else
    echo "No REMOTE_SCRIPT found : Using default"
    echo -e "#!/bin/bash" > remote_script.sh
fi
echo -e "\n./worker.pl $HEADNODE:$WORKER_PORT 0099 ~/user/$USER/workerlog -w $WALLTIME\n" >> remote_script.sh
chmod a+x remote_script.sh

###############################################################################
# Setting up hdfs for workers
# Clean and repopulate INPUT_DIR folder with WORKER_COUNT number of fake data
# files.
###############################################################################
hadoop dfs -rmr $INPUT_DIR
mkdir -p fake_data
for i in `seq 1 1 $WORKER_COUNT`
do
    echo "Fake data $i" > "fake_data/fake_data.$i.gz"
done
hadoop dfs -copyFromLocal ./fake_data $INPUT_DIR
rm -rf fake_data
###############################################################################
echo "Removing $OUTPUT"
hadoop dfs -rmr $OUTPUT
###############################################################################

###############################################################################
# Workers are submitted as map jobs to hadoop
# The timeout is in milliseconds.
# Files needed for remote execution are passed along
# using the -file option
# -cmdenv allows you to set environment variables
###############################################################################
echo "Starting hadoop jobs"

hadoop jar "$HADOOP_STREAMING" \
    -D mapred.task.timeout=$(($WALLTIME*60000)) \
    -input  $INPUT_DIR \
    -output $OUTPUT \
    -file ./remote_script.sh \
    -file ./worker.pl \
    -mapper "./remote_script.sh"

#    -cmdenv PYTHONPATH=/tmp/python-libs/lib/python/ \
#    -cmdenv NLTK_DATA=/tmp/python-libs/lib/python/data \
#    -cmdenv PYWEBSERVER="$HEADNODE:$PUBLISH_PORT" \

stop-coaster-service

echo "Removing results directory"
rm -rf ./results &> /dev/null

echo "Copying $OUTPUT from hdfs"
hadoop dfs -copyToLocal $OUTPUT ./

