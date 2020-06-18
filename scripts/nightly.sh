#!/usr/bin/env bash

if [ -z "$STAGING_BRANCH" ]
then
    STAGING_BRANCH=staging
fi

BASEDIR=$(dirname "$BASH_SOURCE")
cd $BASEDIR/../
BASEDIR=$( pwd )
PULLNO=$STAGING_BRANCH
STAGE="$BASEDIR/code/$STAGING_BRANCH"
DATA="$BASEDIR/code/data/$PULLNO"

sudo nohup bash -c "$BASEDIR/scripts/build.sh $PULLNO drop | while IFS= read -r l; do echo \"[\$(date '+%Y-%m-%d %H:%M:%S')] \$l\"; done >> \"$DATA/build.log\"" >/dev/null 2>&1 &