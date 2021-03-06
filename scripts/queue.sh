#!/usr/bin/env bash
# Loop over waiting builds and run the build script for each.

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
count=$( ps aux --no-headers 2>&1 | grep -c "bash /var/app/current/scripts/queue.s[h]" 2>&1 )
if [ "$count" -gt 2 ]
then
    echo "Already running queue worker ($count)"
    exit 0
fi
if [ -f "/opt/elasticbeanstalk/support/envvars" ]
then
    . /opt/elasticbeanstalk/support/envvars
fi

BASEDIR=$(dirname "$BASH_SOURCE")
cd $BASEDIR/../
BASEDIR=$( pwd )
USER="webapp"

function dataprep {
    if [ ! -d "$DATA" ]
    then
        mkdir -p "$DATA"
        chown -R $USER:$USER "$DATA"
        chgrp -R $USER "$DATA"
        chmod -R ug+wx "$DATA"
    fi
}

while true
do
    # Loop looking for files in the queue folder by ####.pull
    for file in $BASEDIR/queue/*.pull
    do
        [ -e "$file" ] || continue

        # Delete the file, and spin a process for build.sh
        rm -f "$file"
        file=$(basename -- "$file")
        PULLNO="${file%.*}"
        echo "Running build request for $PULLNO"

        # Prep for output to a logfile.
        DATA="$BASEDIR/code/data/$PULLNO"
        dataprep

        sudo nohup bash -c "$BASEDIR/scripts/build.sh $PULLNO | while IFS= read -r l; do echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] \$l\"; done >> \"$DATA/build.log\"" >/dev/null 2>&1 &
    done
    sleep .5
done