# Swift on Hadoop

### Get swift installed.

* Download the swift package from http://swift-lang.org/downloads/index.php
* Untar swift package : tar -xzf swift-0.94.1.tar.gz
* Add the following to .bashrc to get swift in path

```bash
export PATH=$PWD/swift-0.94.1/bin:$PATH
# Check by running:
swift -version
```

### Start workers on hadoop.

Before swift scripts can be run across the hadoop cluster, swift workers must
be started on the hadoop nodes. These workers allow swift to execute its jobs
on the cluster. First the start_hadoop_workers.sh script must be configured
for that jobs that you would run on the cluster.

Here's the configuration section of the hadoop_coasters/start_hadoop_workers.sh
script:

```bash
#Number of workers started by hadoop for swift
WORKER_COUNT=10
#Worker walltime in minutes
WALLTIME=240
#Remote setup script
REMOTE_SCRIPT=./install_nltk.sh
#Input data dir on hdfs to start workers
INPUT_DIR="/user/$USER/tmp"
#IP of headnode
HEADNODE="http://128.135.159.52"
# Hadoop streaming jar
HADOOP_STREAMING="/opt/hadoop-0.20.203.0/contrib/streaming/hadoop-streaming-0.20.203.0.jar"
#Port for python webserver
PUBLISH_PORT=$(( 55000 + $(($RANDOM % 1000))  ))
#Port used by workers to connect back to coaster service
WORKER_PORT=$((  50000 + $(($RANDOM % 1000 )) ))
#Port used by swift to talk to the coaster service
SERVICE_PORT=$(( 51000 + $(($RANDOM % 1000 )) ))
#Output from scripts on HDFS
OUTPUT=/user/$USER/results

```

Ensure that the WORKER_COUNT is set to a number appropriate for the size of
the jobs that you wish to run. Since swift workers fork off tasks submitted to it,
and the node is generally a commodity system, the nature of the app would generally
determine how many cores it uses.

The WALLTIME is a hard limit applied to both swift workers as well as the hadoop
job which starts up the workers. As a result, ensure that the WALLTIME exceeds the
longest duration your jobs may run with the resources requested.

REMOTE_SCRIPT points to bash script, which is shipped to the hadoop nodes, and executed
before the workers initialise. Node specific installations and data setups can be done
using this script. These setups generally persist unless you have added a mechanism to
do cleanups.

HEADNODE should be set to either a network accessible URL of the headnode or the IP of
the headnode, where you'd be running Swift from. Prefix the URL/IP with "http://".
The default is set to the address of the OCCY-hadoop cluster

HADOOP_STREAMING should be set to the full path to the hadoop streaming jar file on the
hadoop headnode. By default this is set to point to the jar file on the OCCY-hadoop
cluster.

INPUT_DIR, should be set to a temporary directory on the HDFS.

Ensure that the PUBLISH_PORT, WORKER_PORT and SERVICE_PORT are all withing ranges that
are not blocked by firewalls.

Once you've setup the configurations,

```bash
# start workers :
./hadoop_coasters/start_hadoop_workers.sh
```

### Run swift workflows.

* Update run-swift.sh for your configs
* Edit stable at your installation of swift-0.94.1
* Point DIR at the default dataset you want to use
* CONFIG variable should by default be set to "hadoop" on OCCY.

```bash
#To run:
./run-swift.sh /relative/path/to/your-dataset
```

### Advanced modifications

The hadoop worker submission commandline can be modified with to do several
interesting and useful things. Here are some examples:

Set -cdmenv <VAR>=<values>  ,to set environment variables for the worker which
is also inherited by the tasks which run under it.

Set -file <file> , to move a file to every workers sandbox directory. This can be
used to stage installation packages easily.

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


- [ ] Mechanism to determine the number of workers
- [ ] Testing for long-runs
- [ ] Documentation cleanup
- [ ] Document setting walltimes for hadoop workers and worker behavior across multiple runs
- [ ] run-swift.sh configs are pretty horrible, clean this up