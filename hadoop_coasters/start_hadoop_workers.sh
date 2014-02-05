#!/bin/bash


############# Settings ################
#Input data dir on hdfs to start workers
INPUT_DIR="/user/ybabuji/fake"
#Remote setup script
REMOTE_SCRIPT=/home/agerow/knowledge_lab-tfidf_example/hadoop_coasters/install_nltk.sh
#Port for python webserver
PUBLISH_PORT=55009
#Port used by workers to connect back to coaster service
WORKER_PORT=50015
#IP of headnode
HEADNODE="http://128.135.159.52"
#Worker walltime
WALLTIME=10080
#Output from scripts on HDFS
OUTPUT=/user/agerow/results
#######################################

rm -rf test-2014*
rm -rf driver*

echo "Killing previous java services"
killall -u $USER java -9

echo "Starting new coaster-service"
coaster-service -p 50001 -localport $WORKER_PORT -nosec -passive &> coaster-service.logs &

echo "Starting python web-server"
python -m SimpleHTTPServer $PUBLISH_PORT &> pyserver.log &

cp $REMOTE_SCRIPT remote_script.sh
echo "./worker.pl $HEADNODE:$WORKER_PORT 0099 ~/user/agerow/workerlog -w $WALLTIME" >> remote_script.sh
chmod a+x remote_script.sh

echo "Removing $OUTPUT"
hadoop dfs -rmr $OUTPUT

echo "Kicking job"
hadoop jar /opt/hadoop-0.20.203.0/contrib/streaming/hadoop-streaming-0.20.203.0.jar \
    -input  $INPUT_DIR \
    -output $OUTPUT \
    -cmdenv PYTHONPATH=/tmp/python-libs/lib/python/ \
    -cmdenv NLTK_DATA=/tmp/python-libs/lib/python/data \
    -file ./remote_script.sh \
    -file ./worker.pl \
    -mapper "./remote_script.sh"

echo "Removing results directory"
rm -rf ./results &> /dev/null

echo "Copying $OUTPUT from hdfs"
hadoop dfs -copyToLocal $OUTPUT ./
