#!/usr/bin/env bash
# Build a PR directory as needed.

# Caveats:
#    Temporary - Test environments will be disbanded when not in use, and will be re-built if the PR changes.
#    Public - Test environments are public, shared and by that nature, insecure. Do not store private information here.
#    Email - Emails can not be sent from the environment, but you can view them as if they were.

# Paths:
#    /code/pulls                Pull requests
#    /code/pulls/xxxx           Pull request
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

FREQUENCY=5
BASEDIR=$(dirname "$BASH_SOURCE")
BASEDIR=$( pwd )
STAGE="$BASEDIR/code/stage"
DATA="$BASEDIR/code/data/$1"
PULL="$BASEDIR/code/pulls/$1"
OVERRIDES="$BASEDIR/overrides"

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

if [ ! -z $(find "$PULL/app/bootstrap.php.cache" -mmin -$FREQUENCY 2>/dev/null) ]
then
    echo "The PULL is recent enough. Builds permitted every $FREQUENCY minutes."
else
    mkdir -p "$DATA"
    cd "$DATA"
    chown -R webapp:webapp .
    chgrp -R webapp .
    chmod -R ug+wx .

    mkdir -p "$PULL"
    echo "{'pull':$1,'status':'building'}" > "$DATA/status.json"

    if [ ! -z $(find "$STAGE/app/bootstrap.php.cache" -mmin -$FREQUENCY 2>/dev/null) ]
    then
        echo "Staging working copy is recent enough. Builds permitted every $FREQUENCY minutes."
    else
        echo "Refreshing staging branch"
        if [ ! -d "$STAGE" ]
        then
            git clone -b staging --single-branch --depth 1 https://github.com/mautic/mautic.git "$STAGE"
        fi
        cd "$STAGE"
        git clean -fd
        git reset --hard HEAD
        git pull
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

    echo "Creating/updating pull request workspace"
    rsync -aLrqW --delete --force "$STAGE/" "$PULL"
    if [ $? != 0 ]
    then
        echo "Failed sync!"
        exit 1
    fi

    echo "Applying pull request patch"
    cd "$PULL"
    curl -L "https://github.com/mautic/mautic/pull/$1.diff" | git apply -v

    if [ $? != 0 ]
    then
        echo "Failed patch!"
        exit 1
    fi

    echo "Getting mailhog config"
    # TODO

    # echo "Creating path rules"
    # Log everything to one file.
    # Set mailhog settings and other perms.

    echo "Syncing custom parameter files"
    rsync -avh --update "$OVERRIDES/" "$PULL"

    echo "Clearing cache"
    rm -rf "$PULL/app/cache/*"

    echo "Clearing temp"
    rm -rf "/tmp/$1"
    mkdir -p "/tmp/$1"

    echo "Creating/updating database"
    cd "$PULL"
    console doctrine:database:create --no-interaction --if-not-exists
    console mautic:install:data -n -vvv
    console doctrine:migrations:version --add --all --no-interaction -vvv

    echo "{'pull':$1,'status':'ready'}" > "$DATA/status.json"
fi