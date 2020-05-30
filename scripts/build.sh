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
if [ -z "$PULLFREQUENCY" ]
then
    PULLFREQUENCY=1
fi
if [ -z "$STAGEFREQUENCY" ]
then
    STAGEFREQUENCY=30
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
    echo '{"sha":"'$SHA'","date":"'$DATE'","pull":"'$PULLNO'","status":"'$1'","error":"'$2'"}' > "$DATA/build.json"
}

function permissions {
    echo "Enforcing permissions"
    cd "$PULL"
    touch app/config/local.php
    mkdir -p var/cache \
        var/logs \
        var/spool \
        media/files \
        translations
    chown -R $USER:$USER .
    chgrp -R $USER . \
        app/bootstrap.php.cache \
        media \
        var/cache \
        var/logs
    chmod -R u+rwX,go+rX,go-w .
    chmod -R ug+wx app/bootstrap.php.cache \
        app/config/local.php \
        media \
        var/cache \
        var/logs
}

function dependencies {
    cd "$PULL"
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
    status 'warming'
    cd "$PULL"
    echo "Warming up caches"
    console cache:warmup --no-optional-warmers --env=dev --quiet
}

function assets {
    cd "$PULL"
    echo "Generating assets"
    if [ -f "$PULL/media/js/app.js" ] || [ -f "$PULL/media/js/app.css" ]
    then
        rm -f "$PULL/media/js/app.js"
        rm -f "$PULL/media/js/app.css"
        console mautic:assets:generate --env=dev
    fi
}

function plugins {
    cd "$PULL"
    echo "Re/loading plugins."
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

function database {
    echo "Re/loading database."
    cd "$PULL"
    DBCREATE=$( console doctrine:database:create --no-interaction --if-not-exists --env=dev )
    echo "$DBCREATE"
    if [[ $DBCREATE == *"Skipped"* ]]
    then
        status 'migrating'
        echo "Running migrations."
        console doctrine:migrations:migrate --no-interaction --env=dev
        echo "Forcing schema updates."
        console doctrine:schema:update --force --env=dev
    else
        status 'installing'
        echo "Running initial schema creation."
        # Mautic 3 now does not create schema on db creation. It is a sepperate step.
        console doctrine:schema:create --env=dev --no-interaction
        echo "Setting migration versions."
        console doctrine:migrations:version --add --all --no-interaction --env=dev
        echo "Installing default fixtures."
        # Mautic 3 now purges the db prior to demo data insertion.
        console doctrine:fixtures:load --append --env=dev -n
        # console mautic:install:data --force --env=dev
    fi
    if [ $? -ne 0 ]
    then
        unlink
        status 'error' 'DB Could not be prepared.'
        exit 1
    fi
}

if [ "$PULLNO" != "$STAGING_BRANCH" ] && [ ! -z $( find "$PATCH" -mmin -$PULLFREQUENCY 2>/dev/null ) ]
then
    echo "The PULL is recent enough. Builds permitted every $PULLFREQUENCY minutes."
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
    if [ ! -z $( find "$STAGE/app/bootstrap.php.cache" -mmin -$STAGEFREQUENCY 2>/dev/null ) ]
    then
        echo "Stage is recent enough. Updates every $STAGEFREQUENCY minutes."
        cd "$STAGE"
        NEWSHA=$( git rev-parse --short HEAD )
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

    # Create/updated pull request folder.
    if [ -d "$PULL" ]
    then
        cd "$PULL"
        SHA=$( git rev-parse --short HEAD )
    fi
    if [ "$NEWSHA" != "$SHA" ]
    then
        unlink
        echo "Syncing request workspace."
        sudo rsync -aLrWq --delete --force $STAGE/ $PULL
        if [ $? -ne 0 ]
        then
            # try again 2
            sudo rsync -aLrWq --delete --force $STAGE/ $PULL
            if [ $? -ne 0 ]
            then
                # try again 3
                sudo rsync -aLrWq --delete --force $STAGE/ $PULL
                if [ $? -ne 0 ]
                then
                    status 'error' 'Could not synchronize files.'
                    exit 1
                fi
            fi
        fi
        CHANGES=1
    fi

    if [ "$PULLNO" != "$STAGING_BRANCH" ]
    then
        # Check if a patch is needed or has already been applied.
        mkdir -p "$PATCHDIR"
        # sudo curl -sfL "$REPO/pull/$1.patch" --output "$PATCH.latest"
        # Diffs are more lenient.
        sudo curl -sfL "$REPO/pull/$1.diff" --output "$PATCH.latest"
        if [ $? -ne 0 ]
        then
            unlink
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
            unlink
            if [ ! -z "$OLDPATCH" ]
            then
                echo "Reverting previous patch"
                sudo git apply --exclude="media/js/app.js" --exclude="media/css/app.css" --exclude="app/bundles/CampaignBundle/Tests/Command/campaign_schema.sql" --whitespace=fix --verbose -R "$PATCH"
                if [ $? -ne 0 ]
                then
                    status 'error' 'Previous patch could not be reverted cleanly, I will have to rebuild.'
                    rm -rf "$PULL"
                    exit 1
                fi
            fi
            cp "$PATCH.latest" "$PATCH"
            rm -f "$PATCH.latest"
            cd "$PULL"
            sudo git apply --exclude="media/js/app.js" --exclude="media/css/app.css" --exclude="app/bundles/CampaignBundle/Tests/Command/campaign_schema.sql" --whitespace=fix --verbose "$PATCH"
            if [ $? -ne 0 ]
            then
                status 'error' 'Patch could not be applied. Try rebasing the branch for this pull request.'
                rm -rf "$PULL"
                exit 1
            fi
            CHANGES=1
        else
            rm -f "$PATCH.latest"
        fi
        if [[ $OLDPATCH == *".js"* ]] || [[ $OLDPATCH == *".css"* ]] || [[ $NEWPATCH == *".js"* ]] || [[ $NEWPATCH == *".css"* ]]
        then
            status 'generating'
            assets
        fi
    fi

    # If there were no changes, end.
    if [ "$CHANGES" -ne 1 ]
    then
        echo "Build is up to date."
        link
        status 'ready'
        exit 0
    fi

    # Check for dependency changes.
    if cmp -s "$STAGE/composer.lock" "$PULL/composer.lock"
    then
        echo "No dependency changes."
    else
        echo "Dependency changes detected in lock."
        status 'composing'
        dependencies
    fi

    overrides

    cacheclear

    permissions

    database

    link

    cachewarm

    plugins

    cd "$PULL"
    SHA=$( git rev-parse --short HEAD )
    DATE=$( git log -1 --format=%cd )
    status 'ready'
fi
