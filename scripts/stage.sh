#!/usr/bin/env bash
# Refresh the stage copy periodically to speed up builds.

if [ -f "/opt/elasticbeanstalk/support/envvars" ]
then
    . /opt/elasticbeanstalk/support/envvars
fi
if [ -z "$STAGEFREQUENCY" ]
then
    STAGEFREQUENCY=5
fi
if [ -z "$STAGING_BRANCH" ]
then
    STAGING_BRANCH=staging
fi

BASEDIR=$(dirname "$BASH_SOURCE")
cd $BASEDIR/../
BASEDIR=$( pwd )
REPO="https://github.com/mautic/mautic"
USER="webapp"
PULLNO="$1"
STAGE="$BASEDIR/code/$STAGING_BRANCH"

function dependencies {
    echo "Running composer"
    composer install --no-scripts --no-progress --no-suggest
}

# Create/update stage as needed.
if [ ! -z $( find "$STAGE/app/bootstrap.php.cache" -mmin -$STAGEFREQUENCY 2>/dev/null ) ]
then
    echo "Stage is recent enough. Updates every $STAGEFREQUENCY minutes."
    cd "$STAGE"
else
    echo "Refreshing $STAGING_BRANCH copy"
    if [ ! -d "$STAGE" ]
    then
        git clone -b $STAGING_BRANCH --single-branch --depth 1 $REPO.git "$STAGE"
        cd "$STAGE"
    else
        cd "$STAGE"
        SHA=$( git rev-parse --short HEAD )
    fi
    git pull
    touch app/bootstrap.php.cache
    NEWSHA=$( git rev-parse --short HEAD )
    if [ "$NEWSHA" != "$SHA" ]
    then
        dependencies
    fi
fi
