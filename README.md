
# README for running the Knowledge-Lab TF-IDF example


##Quickstart.

### Get swift installed.

# Use the swift tar ball in the folder
tar -xzf swift-0.94.1.tar.gz
# Add the following to .bashrc to get swift in path
export PATH=$PWD/swift-0.94.1/bin:$PATH
# Check by running:
swift -version


### Start workers on hadoop.

Hadoop workers would need to be restarted usually after each swift run.
If workers are left without work for extended periods of time, they generally
shutdown ahead of their walltimes, by hadoop. There is a hard walltime set by
swift on the workers, which can be modified in the start-hadoop-workers.sh script.

```bash
# start workers :
./hadoop_coasters/start_hadoop_workers.sh
```

### Run swift workflows.

* Update run-swift.sh for your configs
* Point stable at your installation of swift-0.94.1
* Point DIR at the default dataset you want to use
* CONFIG variable should by default be set to "hadoop" on OCCY.

```bash
#To run:
./run-swift.sh /relative/path/to/your-dataset
```

### Cleanup.

You might see swift errors when running from a directory with previous results.
You could clean this out with rm /path/to/dir/*{tf*,err,vocab}

### If you run into anything unexpected, please email <swift-user@ci.uchicago.edu>

### TODO LIST

[ ] Mechanism to determine the number of workers
[ ] Testing for long-runs
[ ] Documentation cleanup