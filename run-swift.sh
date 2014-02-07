#!/bin/bash


# The config style to use
# Other configs let you connect to Beagle,midway,OpenScienceGrid,
# Cloud services etc.
# TODO : Add configs to a catalog

CONFIG="hadoop"
TRUNK="/home/ybabuji/swift-trunk/cog/modules/swift/dist/swift-svn/bin"
#STABLE="/home/ybabuji/swift-0.94.1/bin"
STABLE="/home/ybabuji/swift-0.94/cog/modules/swift/dist/swift-svn/bin"

# Default input directory
DIR="-data=./100_monthly_abstracts-abridged"
if [ ! -z "$1" ]
then
    DIR="-data=./$1"
fi

if [ $CONFIG == "old" ]
then
    swift -tc.file old_configs/tc.data \
          -config  old_configs/cf \
          -sites.file old_configs/beagle.xml \
          knowledge.swift

elif [ $CONFIG == "hadoop" ]
then
    PATH=$STABLE:$PATH
    swift -tc.file hadoop_coasters/apps \
          -config  hadoop_coasters/swift.properties \
          -sites.file hadoop_coasters/sites.xml \
          knowledge.swift $DIR

elif [ $CONFIG == "new" ]
then
    echo "New config [ Must load Swift manually ]"
    #export PATH=/scratch/midway/yadunand/swift-0.95/cog/modules/swift/dist/swift-svn/bin:$PATH
    export PATH=$TRUNK:$PATH
    swift -properties new_configs/swift.properties.midway.local knowledge.swift $DIR
fi
