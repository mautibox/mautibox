#!/usr/bin/env bash
# mautic.install.id 1.0.0
# Supports:
# 	- DigitalOcean LEMP/LAMP
# 		- Standard /var/www/html
# 	- Cloudways LAMP + Varnish + nGinx + Memcache
#		- Manual steps reccomended:
#			- Upgrade PHP to 7.1
#			- Upgrade MySQL to 5.7
#		- Starts in /home/master
# 		- Custom symlink to /home/master/applications/xxxxx/public_html
#		- UI based settings override the /etc/php/7.X/fpm/php.ini file automatically, write permissions restricted.

#		- No email password handover
#		- An anoying SSH paste mechanism.

# Prepare error trapping.
set -e
function fdebug
{
	last_command=$current_command
	current_command=$BASH_COMMAND
}
function fexit 
{
	if [ ! $? -eq 0 ]
	then
		echo -e "${RED}ERROR: Mautic installation was unable to complete. \"${last_command}\" returned $?.${NC}"
	fi
	if [ -d "$tmp" ]
	then
		rm -rf "$tmp"
	fi
	if [ -f "$self" ]
	then
		shred -u "$self"
	fi
}
clear
trap fdebug DEBUG
trap fexit EXIT
self="$0"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check dependencies
if [ -z $( which ps ) ]
then
	echo "ps is required."
	exit 1
fi
if [ -z $( which grep ) ]
then
	echo "grep is required."
	exit 1
fi
if [ -z $( which php ) ]
then
	echo "php is required."
	exit 1
fi

# Capture MySQL credentials.
if [ -f /root/.digitalocean_password ]
then
	# Default DigitalOcean credentials.
	mysql_user="root"
	. /root/.digitalocean_password
	mysql_db="mautic"
else
	echo "Please provide your MySQL credentials."
	read -p 'Database Name: ' mysql_db
	read -p 'Database Username: ' mysql_user
	read -sp 'Database Password: ' root_mysql_pass
fi

# Prepare temp folder.
tmp=$( mktemp -d -t tmp.mautic-XXXXX )
cd "$tmp"

# Get latest Mautic version.
if [ -z $( which curl ) ]
then
	sudo apt install curl -q >/dev/null 2>&1
	if [ -z $( which curl ) ]
	then
		echo -e "${RED}ERROR: Mautic installation cancelled. Please ensure Curl is installed.${NC}"
		exit 1
	fi
fi
VERSION=$( curl -s -S "https://api.github.com/repos/mautic/mautic/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' )
if [ -z $VERSION ]
then
	echo -e "${RED}ERROR: Mautic installation cancelled. Could not access latest release from Github.${NC}"
	exit 1
fi

# Download the tar.gz of the latest version.
echo "Installing Mautic $VERSION"
FILENAME='mautic-'$VERSION'.tar.gz'
curl -sLo $FILENAME "https://github.com/mautic/mautic/archive/"$VERSION'.tar.gz'
tar -xzf $FILENAME

# Check for a pre-existing copy of mautic.
if [ ! -z $( cat /var/www/html/README.md | grep 'mautic' ) ]
then
	# TODO - Handle previous installations!
	# Make a backup of the codebase.
	# Make a backup of the DB.

	# Copy over local config and plugins.
	# rsync -avhL mautic/media/files/ /efs/mautic/media/files/
	# rsync -avhL mautic/media/dashboards/ /efs/mautic/media/dashboards/
	# rsync -avhL mautic/media/images/ /efs/mautic/media/images/
	# rsync -avhL mautic/translations/ /efs/mautic/translations/

	# Run composer if there are third-party dependencies.
fi

# Enforce permissions.
cd "mautic-$VERSION"
touch ./app/bootstrap.php.cache \
	./.php_cs
mkdir -p ./app/cache/prod/data \
	./app/logs \
	./app/spool \
	./media/files \
	./translations
chown -R www-data:www-data .
chgrp -R www-data . \
	./app/bootstrap.php.cache \
	./.php_cs \
	./media \
	./app/cache \
	./app/logs
chmod -R u+rwX,go+rX,go-w .
chmod -R ug+wx ./app/bootstrap.php.cache \
	./.php_cs \
	./media \
	./app/cache \
	./app/logs

# Enforce default DB/Install settings.

# Run install/update/migrate on the DB.
# Hot-swap the html folder.

# Create cron tasks.
mkdir -p /home/www-data
chown -R www-data:www-data /home/www-data
crontab -u www-data -r
cat <<EOF >> /etc/cron.d/mautic
# Standard cron tasks for mautic.

# SEGMENTS
# To keep the segments current.
1,8,15,22,29,36,43,50,57 * * * * www-data php /var/www/html/app/console mautic:segments:update --quiet >>/var/www/html/app/logs/cron.log 2>&1

# CAMPAIGNS
# To execute campaigns events.
* * * * * www-data php /var/www/html/app/console mautic:campaigns:trigger >>/var/www/html/app/logs/cron.log 2>&1
# To keep campaigns updated with applicable contacts.
2,9,16,23,30,37,44,51,58 * * * * www-data php /var/www/html/app/console mautic:campaigns:rebuild --quiet >>/var/www/html/app/logs/cron.log 2>&1
# To send frequency rules rescheduled marketing campaign messages.
3,10,17,24,31,38,45,52,59 * * * * www-data php /var/www/html/app/console mautic:messages:send >>/var/www/html/app/logs/cron.log 2>&1

# EMAIL
# Process Email Queue.
* * * * * www-data php /var/www/html/app/console mautic:emails:send >>/var/www/html/app/logs/cron.log 2>&1
# Fetch and Process Monitored Email.
4,11,18,25,32,39,46,53 * * * * www-data php /var/www/html/app/console mautic:email:fetch >>/var/www/html/app/logs/cron.log 2>&1
# Send scheduled broadcasts / segment emails.
5,12,19,26,33,40,47,54 * * * * www-data php /var/www/html/app/console mautic:broadcasts:send >>/var/www/html/app/logs/cron.log 2>&1

# SOCIAL
# Iterates through social monitors.
6,13,20,27,34,41,48,55 * * * * www-data php /var/www/html/app/console mautic:social:monitoring >>/var/www/html/app/logs/cron.log 2>&1

# WEBHOOKS
# Send webhook payloads. These are sent in real-time by default, but should be switched to offline processing.
7,14,21,28,35,42,49,56 * * * * www-data php /var/www/html/app/console mautic:webhooks:process >>/var/www/html/app/logs/cron.log 2>&1

# IMPORTS
# To run imports in offline processing.
*/10 * * * * www-data php /var/www/html/app/console mautic:import --quiet >>/var/www/html/app/logs/cron.log 2>&1

# IP Lookup
# Update maxmind databse at 9am on first Tuesday of each month.
0 9 * * 2 www-data [ `date +\%d` -le 7 ] && php /var/www/html/app/console mautic:iplookup:download >>/var/www/html/app/logs/cron.log 2>&1
EOF
chown root:root /etc/cron.d/mautic
chmod 0644 /etc/cron.d/mautic

# Optimize PHP.
apt-get -y install gcc g++ make autoconf libc-dev pkg-config php-dev php-pear php-zip php-xml php-imap php-mbstring
pecl channel-update pecl.php.net
phpdismod -v ALL -s ALL apcu
phpenmod -v ALL -s ALL pdo opcache mcrypt json curl mbstring
# Messy install of APCuBC
no | pecl install --force apcu_bc-beta
# Messy installation for mailparse to avoid mbstring error.
pecl download mailparse-3.0.2
tar xvzf mailparse-3.0.2.tgz
cd mailparse-3.0.2
phpize
./configure
sed -i \
  's/^\(#error .* the mbstring extension!\)/\/\/\1/' \
  mailparse.c
make
make install
# Cleanup apc/apcu/mailparse from manual php.ini. Not necessary for DO currently.
# sed '/extension=\"apc.so\"/d' /etc/php.ini > /etc/php.ini
# sed '/extension=\"apcu.so\"/d' /etc/php.ini > /etc/php.ini
for VER in /etc/php/*
do
	if [ -d "${VER}" ]
	then
		cat <<EOF >> /etc/php/$VER/fpm/90-mautic-fpm.ini
; This file is generated by the mautic installer for FPM and CLI.
; Default upload limits for heavy CSV imports.
post_max_size = 100M
upload_max_filesize = 100M

; Reverse proxies will typically time out at 100s, so lock that as the limit.
max_execution_time = 100

; Low limit for production FPM
memory_limit = 256M

; Session lifespan of 3 hours.
session.gc_maxlifetime = 10800

; Generally improve performance with opcache.
[opcache]
opcache.enable = On
opcache.enable_cli = On
opcache.validate_timestamps = On
opcache.revalidate_freq = 300
opcache.memory_consumption = 256
opcache.file_cache="/tmp/php-opcache"
opcache.file_cache_consistency_checks = On

[apc]
; APCu must be loaded before APC Backward Compantibility
extension="apcu.so"
extension="apc.so"
apc.enabled = On
apc.enable_cli = On
apc.shm_size = 256M

; Enable mailparse last.
extension=mailparse.so
EOF
		cat <<EOF >> /etc/php/$VER/cli90-mautic-fpm.ini
; This file is generated by the mautic installer for FPM.
; Increased memory limit for CLI
memory_limit = 512M

; Max executime time will typically be overriden as needed.
max_execution_time = 600

; Include opcache in CLI with file mode.
[opcache]
opcache.enable = On
opcache.enable_cli = On
opcache.validate_timestamps = On
opcache.revalidate_freq = 300
opcache.memory_consumption = 256
opcache.file_cache="/tmp/php-opcache"
opcache.file_cache_only = On
opcache.file_cache_consistency_checks = On

[apc]
; APCu must be loaded before APC Backward Compantibility
extension="apcu.so"
extension="apc.so"
apc.enabled = On
apc.enable_cli = On
apc.shm_size = 256M

; Enable mailparse last.
extension=mailparse.so
EOF
		sudo service php$VER-fpm reload
	fi
done
# Configure Nginx/Apache
