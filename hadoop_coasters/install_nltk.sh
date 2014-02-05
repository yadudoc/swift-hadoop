#!/bin/bash

echo "Running on $(hostname -f)"

NLTK_INSTALL_DIR=/tmp/python-libs/lib/python/
LOCK=/tmp/python_install_lock
NLTK_URL=yahoo-headnode.uchicago.edu:55009/nltk-2.0.4.tar.gz

install_nltk()
{
    echo "In install_nltk"
    cd /tmp
    # if install dir exists use it,
    # else try to install, otherwise wait.
    while :
    do
	if [ -d $NLTK_INSTALL_DIR ]       	    
	then
	    echo "Nltk installed"
	    break
	else
	    echo "Attempt to Lock"
	    if $(mkdir -p $LOCK)
	    then
		echo "Acquired Lock"
		# do the install
		wget $NLTK_URL
		tar -xzf nltk-2.0.4.tar.gz && rm -rf nltk-2.0.4.tar.gz
		cd nltk-2.0.4
		mkdir -p $NLTK_INSTALL_DIR
		export PYTHONPATH=$NLTK_INSTALL_DIR:$PYTHONPATH
		python setup.py install --home=/tmp/python-libs
		python -m nltk.downloader -d $NLTK_INSTALL_DIR/data all
		rm -rf $LOCK
		break;
	    else
		echo "Unable to acquire lock"
		sleep 2		
	    fi
	fi	    
    done    
}

pwd
( install_nltk )
pwd

