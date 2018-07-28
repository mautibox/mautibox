#!/usr/bin/env bash
# Build a PR directory as needed.
#
# To run via php: exec('/usr/bin/nohup /bin/bash /var/app/current/build.sh #### >/dev/null 2>&1 &');

if [ -z $( which ps ) ]
then
    echo "ps is required to run this script."
    exit 1
fi
if [ -z $( which grep ) ]
then
    echo "grep is required to run this script."
    exit 1
fi
if [ -z $( which nohup ) ]
then
    echo "nohup is required to run this script."
    exit 1
fi
if [ -z "$1" ]
then
    echo "Please provide a pull request number"
    exit 1
fi
if [ $( ps aux --no-headers 2>&1 | grep -c "$0 $@" 2>&1 ) -gt 1 ]
then
    echo "Already running."
    exit 0
fi
if [ -f "/opt/elasticbeanstalk/support/envvars" ]
then
    . /opt/elasticbeanstalk/support/envvars
fi

BASEDIR=$(dirname "$BASH_SOURCE")
cd $BASEDIR/../
BASEDIR=$( pwd )

# @todo - Loop looking for files in the queue folder by ####.pull

# @todo - Delete the file, and spin a process for build.sh

# @todo - Sleep 1 second.