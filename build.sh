#!/usr/bin/env bash
# Build a PR directory as needed.

# set -e

# Prep:
# composer global require hirak/prestissimo

FREQUENCY=10
BASEDIR=$(dirname "$BASH_SOURCE")
BASEDIR=$( pwd )
STAGING="$BASEDIR/staging"
PR="$BASEDIR/pr/$1"

mkdir -p "$BASEDIR/pr"
mkdir -p "$BASEDIR/status"

if [ -z "$1" ] 
then
	echo "Please provide a PR number"
	exit 1
fi

if [ ! -z $(find "$PR/app/bootstrap.php.cache" -mmin -$FREQUENCY 2>/dev/null) ]
then
	echo "PR is recent enough."
else
	mkdir -p "$PR"
	echo "{'status': 'building'}" > "$BASEDIR/status/$1.json"

	if [ ! -z $(find "$STAGING/app/bootstrap.php.cache" -mmin -$FREQUENCY 2>/dev/null) ]
	then
		echo "Staging branch recent enough"
	else
		echo "Refreshing staging branch"
		if [ ! -d "$STAGING" ]
		then
			git clone -b staging --single-branch --depth 1 https://github.com/mautic/mautic.git "$STAGING"
		fi
		cd "$STAGING"
		git clean -fd
		git reset --hard HEAD
		git pull
		composer install --no-scripts --no-progress --no-suggest
		touch app/bootstrap.php.cache \
			.php_cs
		mkdir -p app/cache \
			app/logs \
			app/spool \
			media/files \
			translations
		chown -R webapp:webapp .
		chgrp -R webapp . \
			app/bootstrap.php.cache \
			.php_cs \
			media \
			app/cache \
			app/logs
		chmod -R u+rwX,go+rX,go-w .
		chmod -R ug+wx app/bootstrap.php.cache \
			.php_cs \
			media \
			app/cache \
			app/logs
	fi

	echo "Creating/updating pull request workspace"
	rsync -aLrqW --delete --force "$STAGING/" "$PR"
	if [ $? == 0 ]
	then
		echo "Failed sync!"
		exit 1
	fi

	echo "Applying pull request patch"
	cd "$PR"
	curl -L "https://github.com/mautic/mautic/pull/$1.diff" | git apply -v

	if [ $? == 0 ]
	then
		echo "Failed patch!"
		exit 1
	fi

	echo "Getting mailhog config"
	# TODO

	echo "Creating path rules"
	# Log everything to one file.
	# Set mailhog settings and other perms.

	echo "Creating parameters file"
	# TODO

	echo "Creating/updating database"
	console doctrine:database:create --no-interaction --if-not-exists
	console mautic:install:data -n -vvv
	console doctrine:migrations:version --add --all --no-interaction -vvv

	echo "{'status': 'building'}" > "$BASEDIR/status/$1.json"
fi