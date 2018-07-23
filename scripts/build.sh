#!/usr/bin/env bash
# Build a PR directory as needed.

# set -e

# Prep:
# composer global require hirak/prestissimo

BASEDIR=$(dirname "$BASH_SOURCE")
cd $BASEDIR/../
BASEDIR=$( pwd )
REPO="https://github.com/mautic/mautic"
PULLNO="$1"
STAGE="$BASEDIR/code/stage"
DATA="$BASEDIR/code/data/$PULLNO"
PULL="$BASEDIR/code/pulls/$PULLNO"
PATCHDIR="$BASEDIR/code/pulls/$PULLNO/.patches"
PATCH="$BASEDIR/code/pulls/$PULLNO/.patches/$PULLNO.patch"
OVERRIDES="$BASEDIR/overrides"
DATE=""
SHA=""
NEWSHA=""
OLDPATCH=""
NEWPATCH=""
CHANGES=0

if [ -z "$1" ]
then
    echo "Please provide a pull request number"
    exit 1
fi

if [ -z "$FREQUENCY" ]
then
    FREQUENCY=1
fi

function console {
    if [ -f "/opt/elasticbeanstalk/support/envvars" ]
    then
        sudo -u webapp bash -c ". /opt/elasticbeanstalk/support/envvars ; /usr/bin/php app/console $@"
    else
        php app/console $@
    fi
}

function status {
    echo "New status: $1"
    echo '{"sha":"'$SHA'","date":"'$DATE'","pull":'$PULLNO',"status":"'$1'"}' > "$DATA/status.json"
}

function permissions {
    echo "Correcting permissions"
    touch app/config/local.php
    mkdir -p app/cache \
        app/logs \
        app/spool \
        media/files \
        translations
    chown -R webapp:webapp .
    chgrp -R webapp . \
        app/bootstrap.php.cache \
        media \
        app/cache \
        app/logs
    chmod -R u+rwX,go+rX,go-w .
    chmod -R ug+wx app/bootstrap.php.cache \
        app/config/local.php \
        media \
        app/cache \
        app/logs
}

function dependencies {
    echo "Running composer"
    composer install --no-scripts --no-progress --no-suggest
}

function overrides {
    echo "Syncing overrides"
    rsync -avh --update "$OVERRIDES/" "$PULL"
}

function cacheclear {
    echo "Clearing tmp and cache"
    if [ -d "/tmp/$1" ]
    then
        rm -rf "/tmp/$1/*"
    else
        mkdir -p "/tmp/$1"
    fi
    if [ -d "$PULL/app/cache" ]
    then
        rm -rf "$PULL/app/cache/*"
    fi
}

if [ ! -z $( find "$PATCH" -mmin -$FREQUENCY 2>/dev/null ) ]
then
    echo "The PULL is recent enough. Builds permitted every $FREQUENCY minutes."
else
    # Prep data folder.
    if [ ! -d "$DATA" ]
    then
        mkdir -p "$DATA"
        chown -R webapp:webapp "$DATA"
        chgrp -R webapp "$DATA"
        chmod -R ug+wx "$DATA"
    fi

    #  Prep pull folder and build status.
    if [ ! -d "$PULL" ]
    then
        mkdir -p "$PULL"
        status 'building'
    fi

    # Create/update stage as needed.
    if [ ! -z $( find "$STAGE/app/bootstrap.php.cache" -mmin -$FREQUENCY 2>/dev/null ) ]
    then
        echo "Staging working copy is recent enough. Builds permitted every $FREQUENCY minutes."
        cd "$STAGE"
        NEWSHA=$( git rev-parse --short HEAD )
    else
        echo "Refreshing stage"
        if [ ! -d "$STAGE" ]
        then
            git clone -b staging --single-branch --depth 1 $REPO.git "$STAGE"
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

    # Create/updated pull request folder.
    if [ -d "$PULL" ]
    then
        cd "$PULL"
        SHA=$( git rev-parse --short HEAD )
    fi
    if [ "$NEWSHA" != "$SHA" ]
    then
        echo "Syncing pull request workspace"
        rsync -aLrqW --delete --force "$STAGE/" "$PULL"
        if [ $? -ne 0 ]
        then
            status 'error'
            echo "Failed sync!"
            exit 1
        fi
        CHANGES=1
    fi

    # Check if a patch is needed or has already been applied.
    mkdir -p "$PATCHDIR"
    curl -sfL "$REPO/pull/$1.patch" --output "$PATCH.new"
    if [ $? -ne 0 ]
    then
        status 'error'
        echo "Patch could not be downloaded."
        exit 1
    fi
    NEWPATCH=$( cat "$PATCH.new" )
    if [ -z "$NEWPATCH" ]
    then
        status 'error'
        echo "Patch is empty."
        exit 1
    fi
    if [ -f "$PATCH" ]
    then
        OLDPATCH=$( cat "$PATCH" )
    fi
    if [ "$OLDPATCH" != "$NEWPATCH" ]
    then
        cp "$PATCH.new" "$PATCH"
        rm -f "$PATCH.new"
        cd "$PULL"
        git apply --whitespace=nowarn --verbose "$PATCH"
        if [ $? -ne 0 ]
        then
            status 'error'
            echo "Patch could not be applied cleanly."
            exit 1
        fi
        CHANGES=1
    fi

    # If there were no changes, end.
    if [ "$CHANGES" -ne 1 ]
    then
        echo "Existing environment is up to date."
        exit 0
    fi

    # Check for css/js changes

    # Check for dependency changes.
    if cmp "$STAGE/composer.lock" "$PULL/composer.lock"
    then
        cd "$PULL"
        echo "Possible dependency changes detected"
        dependencies
    fi

    overrides

    cacheclear

    permissions

    echo "Building/updating database"
    cd "$PULL"
    console doctrine:database:create --no-interaction --if-not-exists
    console mautic:install:data -n -vvv
    console doctrine:migrations:version --add --all --no-interaction -vvv

    cd "$PULL"
    SHA=$( git rev-parse --short HEAD )
    DATE=$( git log -1 --format=%cd )
    status 'ready'
fi