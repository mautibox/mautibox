#!/usr/bin/env bash
# Build a PR directory as needed.

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
if [ -z "$1" ]
then
    echo "Please provide a pull request number"
    exit 1
fi
count=$( ps aux --no-headers 2>&1 | grep -c "bash /var/app/current/scripts/build.s[h] $1" 2>&1 )
if [ "$count" -gt 2 ]
then
    echo "Already running build for $1 ($count)"
    exit 0
fi
if [ -f "/opt/elasticbeanstalk/support/envvars" ]
then
    . /opt/elasticbeanstalk/support/envvars
fi
if [ -z "$FREQUENCY" ]
then
    FREQUENCY=5
fi

BASEDIR=$(dirname "$BASH_SOURCE")
cd $BASEDIR/../
BASEDIR=$( pwd )
REPO="https://github.com/mautic/mautic"
USER="webapp"
PULLNO="$1"
STAGE="$BASEDIR/code/stage"
DATA="$BASEDIR/code/data/$PULLNO"
PULL="$BASEDIR/code/pulls/$PULLNO"
WEB="$BASEDIR/web"
PATCHDIR="$BASEDIR/code/pulls/$PULLNO/.patches"
PATCH="$BASEDIR/code/pulls/$PULLNO/.patches/$PULLNO.patch"
OVERRIDES="$BASEDIR/overrides"
DATE=""
SHA=""
NEWSHA=""
OLDPATCH=""
NEWPATCH=""
CHANGES=0

function status {
    echo "Status of $PULLNO is now: $1"
    if [ ! -z "$2" ]
    then
        echo "Error: $2"
    fi
    echo '{"sha":"'$SHA'","date":"'$DATE'","pull":'$PULLNO',"status":"'$1'","error":"'$2'"}' > "$DATA/build.json"
}

function permissions {
    echo "Enforcing permissions"
    touch app/config/local.php
    mkdir -p app/cache \
        app/logs \
        app/spool \
        media/files \
        translations
    chown -R $USER:$USER .
    chgrp -R $USER . \
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
    echo "Setting parameters"
    sudo rsync -havIq "$OVERRIDES/" "$PULL"
    # echo "Prepping log space"
    # touch "$DATA/apache.access.log"
    # touch "$DATA/apache.error.log"
    # touch "$DATA/php.error.log"
    echo "SetEnv PULL $PULLNO" >> "$PULL/.htaccess"
    dataprep
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

function cachewarm {
    cd "$PULL"
    echo "Warming up caches"
    console cache:warmup --no-optional-warmers --env=dev --quiet
}

function plugins {
    cd "$PULL"
    echo "Re/loading plugins and warming cache."
    console mautic:plugins:reload --env=dev
}

function link {
    cd "$WEB"
    if [ -L "$PULLNO" ]
    then
        if [ -e "$PULLNO" ]
        then
            echo "Link already exists."
        else
            echo "Creating symlink."
            ln -s "$PULL" "$PULLNO"
        fi
    elif [ -e "$PULLNO" ]
    then
        echo "Creating symlink."
        ln -s "$PULL" "$PULLNO"
    else
        echo "Creating symlink."
        ln -s "$PULL" "$PULLNO"
    fi
}

function unlink {
    cd "$WEB"
    if [ -L "$PULLNO" ]
    then
        if [ -e "$PULLNO" ]
        then
            echo "Removing link."
            rm "$PULLNO"
        else
            echo "Removing link."
            rm "$PULLNO"
        fi
    fi
}

function dataprep {
    if [ ! -d "$DATA" ]
    then
        mkdir -p "$DATA"
        chown -R $USER:$USER "$DATA"
        chgrp -R $USER "$DATA"
        chmod -R ug+wx "$DATA"
    fi
}

if [ ! -z $( find "$PATCH" -mmin -$FREQUENCY 2>/dev/null ) ]
then
    echo "The PULL is recent enough. Builds permitted every $FREQUENCY minutes."
else
    # Prep data folder.
    dataprep

    #  Prep pull folder and build status.
    if [ ! -d "$PULL" ]
    then
        mkdir -p "$PULL"
        status 'building'
        unlink
    fi

    # Create/update stage as needed.
    if [ ! -z $( find "$STAGE/app/bootstrap.php.cache" -mmin -$FREQUENCY 2>/dev/null ) ]
    then
        echo "Stage is recent enough. Updates every $FREQUENCY minutes."
        cd "$STAGE"
        NEWSHA=$( git rev-parse --short HEAD )
    else
        echo "Refreshing stage copy"
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
        echo "Syncing pull request workspace."
        sudo rsync -aLrWq --delete --force $STAGE/ $PULL
        if [ $? -ne 0 ]
        then
            status 'error' 'Could not synchronize files.'
            exit 1
        fi
        CHANGES=1
        unlink
    fi

    # Check if a patch is needed or has already been applied.
    mkdir -p "$PATCHDIR"
    curl -sfL "$REPO/pull/$1.patch" --output "$PATCH.latest"
    if [ $? -ne 0 ]
    then
        status 'error' 'Patch could not be downloaded.'
        exit 1
    fi
    NEWPATCH=$( cat "$PATCH.latest" )
    if [ -z "$NEWPATCH" ]
    then
        status 'error' 'Patch is empty.'
        exit 1
    fi
    if [ -f "$PATCH" ]
    then
        OLDPATCH=$( cat "$PATCH" )
    fi
    if [ "$OLDPATCH" != "$NEWPATCH" ]
    then
        cp "$PATCH.latest" "$PATCH"
        rm -f "$PATCH.latest"
        cd "$PULL"
        git apply --whitespace=nowarn --verbose "$PATCH"
        if [ $? -ne 0 ]
        then
            status 'error' 'Patch could not be applied cleanly.'
            exit 1
        fi
        CHANGES=1
        unlink
    else
        rm -f "$PATCH.latest"
    fi

    # If there were no changes, end.
    if [ "$CHANGES" -ne 1 ]
    then
        echo "Build is up to date."
        link
        status 'ready'
        exit 0
    fi

    # Check for css/js changes

    # Check for dependency changes.
    if cmp "$STAGE/composer.lock" "$PULL/composer.lock"
    then
        cd "$PULL"
        echo "Dependency changes detected."
        dependencies
    fi

    overrides

    cacheclear

    permissions

    echo "Re/loading database."
    cd "$PULL"
    DBCREATE=$( console doctrine:database:create --no-interaction --if-not-exists --env=dev )
    echo "$DBCREATE"
    if [[ $DBCREATE == *"Skipped"* ]]
    then
        echo "Running migrations."
        console doctrine:migrations:migrate --no-interaction --env=dev
        echo "Forcing schema updates."
        console doctrine:schema:update --force --env=dev
    else
        echo "Installing default data."
        console mautic:install:data --force --env=dev
        echo "Setting migration versions."
        console doctrine:migrations:version --add --all --no-interaction --env=dev
    fi
    if [ $? -ne 0 ]
    then
        status 'error' 'DB Could not be prepared.'
        exit 1
    fi

    link

    cachewarm

    plugins

    cd "$PULL"
    SHA=$( git rev-parse --short HEAD )
    DATE=$( git log -1 --format=%cd )
    status 'ready'
fi