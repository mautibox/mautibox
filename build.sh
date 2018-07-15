#!/usr/bin/env bash
# Build a PR directory as needed.

# Caveats:
#    Temporary - Test environments will be disbanded when not in use, and will be re-built if the PR changes.
#    Public - Test environments are public, shared and by that nature, insecure. Do not store private information here.
#    Email - Emails can not be sent from the environment, but you can view them as if they were.

# Paths:
#    /code/pulls                Pull requests
#    /code/pulls/xxxx           Pull request
#    /code/pulls/xxxx/.patches/ Patches applied to the build.
#    /code/stage                Working copy of the core repo with permissions applied for faster local cloning.
#
#    /www/data/xxxx/statis.json Current status of the PR in question.
#    /www/data/xxxx/*.log       Aggregated logs for the PR.
#    /www/index.php             Home page where you select PRs.
#    /www/
#    /www/xxxx                  Symlink to /code/prs/xxxx when ready.
#                               Internal redirect to /www/status when not present.

# Routes:
#    /                          Home page, PR selection, links.
#    /xxxx                      PR number, either status screen or symlink to /code/prs/xxxx
#    /xxxx/data                 Status/logs stream.
#    /xxxx/mail                 Mailhog interface.

# set -e

# Prep:
# composer global require hirak/prestissimo

FREQUENCY=1
BASEDIR=$(dirname "$BASH_SOURCE")
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
    echo "{'sha':'$SHA','date':'$DATE','pull':$PULLNO,'status':'$1'}" > "$DATA/status.json"
}

if [ ! -z $( find "$PATCH" -mmin -$FREQUENCY 2>/dev/null ) ]
then
    echo "The PULL is recent enough. Builds permitted every $FREQUENCY minutes."
else
    if [ ! -d "$PULL" ]
    then
        status 'building'
    fi

    # Prep data folder.
    if [ ! -d "$DATA" ]
    then
        mkdir -p "$DATA"
        chown -R webapp:webapp "$DATA"
        chgrp -R webapp "$DATA"
        chmod -R ug+wx "$DATA"
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
        git clean -fd
        git reset --hard HEAD
        git pull
        NEWSHA=$( git rev-parse --short HEAD )
        if [ "$NEWSHA" != "$SHA" ]
        then
            # Git repository changes detected
            composer install --no-scripts --no-progress --no-suggest
            touch app/bootstrap.php.cache \
                app/config/local.php
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
        mkdir -p "$PULL"
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
    NEWPATCH=$( curl -sL "$REPO/pull/$1.patch" )
    if [ -z "$NEWPATCH" ]
    then
        status 'error'
        echo "Patch diff is empty"
        exit 1
    fi
    if [ -f "$PATCH" ]
    then
        OLDPATCH=$( cat "$PATCH" )
    fi
    if [ "$OLDPATCH" != "$NEWPATCH" ]
    then
        cd "$PULL"
        echo "$NEWPATCH" | git apply -v
        if [ $? -ne 0 ]
        then
            status 'error'
            echo "Failed patch!"
            exit 1
        fi
        mkdir -p "$PATCHDIR"
        echo "$NEWPATCH" > "$PATCH"
        CHANGES=1
    fi

    # If there were no changes, end.
    if [ "$CHANGES" -ne 1 ]
    then
        echo "Existing environment is up to date."
        exit
    fi

    if [[ "$NEWPATCH" = *"composer."* ]]
    then
        echo "Possible composer changes detected"
        cd "$PULL"
        composer install --no-scripts --no-progress --no-suggest
    fi

    echo "Syncing overrides"
    rsync -avh --update "$OVERRIDES/" "$PULL"

    echo "Clearing cache and tmp"
    rm -rf "/tmp/$1" "$PULL/app/cache/*"
    mkdir -p "/tmp/$1"

#    echo "Building/updating database"
#    cd "$PULL"
#    console doctrine:database:create --no-interaction --if-not-exists
#    console mautic:install:data -n -vvv
#    console doctrine:migrations:version --add --all --no-interaction -vvv

    cd "$PULL"
    SHA=$( git rev-parse --short HEAD )
    DATE=$( git log -1 --format=%cd )
    status 'ready'
fi