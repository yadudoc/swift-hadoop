#!/bin/bash

# The config style to use
CONFIG="hadoop"
TRUNK="/home/agerow/swift-trunk/cog/modules/swift/dist/swift-svn/bin"
STABLE="/home/agerow/swift-0.94.1/bin"

DIR="-data=./monthly_abstracts"
if [ ! -z "$1" ]
then
    DIR="-data=./$1"
fi

if [ $CONFIG == "old" ]
then
    swift -tc.file old_configs/tc.data \
          -config  old_configs/cf \
          -sites.file old_configs/beagle.xml \
          knowledge.swift.yadu

elif [ $CONFIG == "hadoop" ]
then
    PATH=$STABLE:$PATH
    swift -tc.file hadoop_coasters/apps \
          -config  hadoop_coasters/swift.properties \
          -minimal.logging \
          -sites.file hadoop_coasters/sites.xml \
          knowledge.swift $DIR

# OR "-reduced.logging"

elif [ $CONFIG == "new" ]
then
    echo "New config [ Must load Swift manually ]" 
    #export PATH=/scratch/midway/yadunand/swift-0.95/cog/modules/swift/dist/swift-svn/bin:$PATH
    swift -properties new_configs/swift.properties.midway.local knowledge.swift.yadu $DIR
fi
