B1;3402;0c# Swift on Hadoop

### Get swift installed

* Download the swift package from http://swift-lang.org/packages/swift-0.94.1.tar.gz
* Untar swift package : tar -xzf swift-0.94.1.tar.gz
* Add the following to .bashrc to get swift in path

**Note:** Swift 0.94.1 is recommended till, [Bug:1203](https://bugzilla.mcs.anl.gov/swift/show_bug.cgi?id=1203)
is fixed on Swift 0.95

```bash
export PATH=$PWD/swift-0.94.1/bin:$PATH
# Check by running:
swift -version
```

### Start workers on hadoop

Before swift scripts can be run across the hadoop cluster, swift workers must
be started on the hadoop nodes. These workers allow swift to execute its jobs
on the cluster. The start_hadoop_workers.sh script must be configured for
that jobs that you would run on the cluster.

Here's the configuration section of the hadoop_coasters/start_hadoop_workers.sh
script:

```bash
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

```

Ensure that the ***WORKER_COUNT*** is set to a number appropriate for the size of
the jobs that you wish to run. Since swift workers fork off tasks submitted to it,
and the node is generally a commodity system, the nature of the app would generally
determine how many cores it uses.

The ***WALLTIME*** is a hard limit applied to both swift workers as well as the hadoop
job which starts up the workers. As a result, ensure that the WALLTIME exceeds the
longest duration your jobs may run with the resources requested. This is different from
the walltime defined in the sites.xml file used by swift's task-scheduling.

***REMOTE_SCRIPT*** points to bash script, which is shipped to the hadoop nodes, and
executed before the workers initialise. Node specific installations and data setups
can be done using this script. These setups generally persist unless you have added
a mechanism to do cleanups. This should be set to *not* use any script by default.

***HEADNODE*** should be set to either a network accessible URL of the headnode or the IP of
the headnode, where you'd be running Swift from. Prefix the URL/IP with "http://".
The default is set to the address of the OCCY-hadoop cluster

***HADOOP_STREAMING*** should be set to the full path to the hadoop streaming jar file
on the hadoop headnode. By default this is set to point to the jar file on the OCCY-hadoop
cluster.

***INPUT_DIR***, should be set to a temporary directory on the HDFS.

***ENABLE_PYTHON_WEBSERVER*** is used to start a python webserver. This could be used to
ship installation packages to nodes for setup. By default it is set to 0, set to 1 to enable.
The ***PUBLISH_PORT*** used by the python webserver can be communicated to the install scripts
using CMD_ENV options to the hadoop job command user later in the script.

Ensure that the ***PUBLISH_PORT***, ***WORKER_PORT*** and ***SERVICE_PORT*** are all
withing ranges that are not blocked by firewalls. The default values are tested only on
OCCY-hadoop cluster.

Once you've setup the configurations,

```bash
# start workers in a separate shell, or as a background process:
./start_hadoop_workers.sh

# Sample output below :
Killing previous java services
java: no process found
Starting new coaster-service
No REMOTE_SCRIPT found : Using default
Deleted hdfs://namenode:9000/user/ybabuji/tmp
Removing /user/ybabuji/results
Deleted hdfs://namenode:9000/user/ybabuji/results
Starting hadoop jobs
packageJobJar: [./remote_script.sh, ./worker.pl, /opt/hadoop-tmp/ybabuji/hadoop-unjar8918026246017889971/] [] /tmp/streamjob3715681231062281263.jar tmpDir=null
14/02/20 16:28:04 INFO lzo.GPLNativeCodeLoader: Loaded native gpl library
14/02/20 16:28:04 INFO lzo.LzoCodec: Successfully loaded & initialized native-lzo library [hadoop-lzo rev 6bb1b7f8b9044d8df9b4d2b6641db7658aab3cf8]
14/02/20 16:28:04 INFO mapred.FileInputFormat: Total input paths to process : 10
14/02/20 16:28:04 INFO streaming.StreamJob: getLocalDirs(): [/opt/hadoop/data1/mapred]
14/02/20 16:28:04 INFO streaming.StreamJob: Running job: job_201312161508_0448
14/02/20 16:28:04 INFO streaming.StreamJob: To kill this job, run:
14/02/20 16:28:04 INFO streaming.StreamJob: /opt/hadoop/bin/../bin/hadoop job  -Dmapred.job.tracker=namenode:9001 -kill job_201312161508_0448
14/02/20 16:28:04 INFO streaming.StreamJob: Tracking URL: http://namenode:50030/jobdetails.jsp?jobid=job_201312161508_0448
14/02/20 16:28:05 INFO streaming.StreamJob:  map 0%  reduce 0%

```

**Note:** Since the hadoop job is used to start swift workers, it would appear that the hadoop job is not making any progress.
This is expected behavior.

### Run swift workflows.

* Once start_hadoop_workers.sh is running either as a background process or in a separate terminal, Swift scripts can be run.
* Go to the swift-hadoop/example folder to run a sample swift script

```bash
# Move to the example folder
cd swift-hadoop/example
# To run:
make
# Or you could run the full command used by Make
swift -tc.file ../apps -sites.file ../sites.xml -config ../swift.properties test.swift

```

### Advanced modifications

The hadoop worker submission commandline can be modified with to do several
interesting and useful things. Here are some examples:

Environment variables can be set on the swift workers by passing them through
the hadoop job which starts the workers. The environment is inherited by the
tasks run on the nodes by swift.

```bash
# Add argument to the hadoop job call
-cdmenv <VAR>=<values>
```

Files, can be moved the workers sandbox directory using the -file option. This can be
used to stage installation packages easily.
```bash
# Add argument to the hadoop job call
-file <file>
```
There is a python webserver that is started by default and the address to that
webserver is set to an environment variable PYWEBSERVER on all workers. This
can be used to download files from the current directory on the headnode.

### Cleanup.

You might see swift errors when running from a directory with previous results.
You could clean the whole directory by running :

```bash
# Cleanup script
./clean.sh
```

### Need help ?

If you run into anything unexpected, please email <swift-user@ci.uchicago.edu>

### TODO LIST

* Re-order the setup to be app independent and maintain separate branch for KLAB
* Documentation cleanup
  ** Document worker starting mechanim
  ** Coasters troubleshooting
  ** Links to swift install and tutorial