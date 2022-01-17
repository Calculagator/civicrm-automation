#!/bin/bash

echo "Shutdown and remove running docker stuff"
#shutdown running stuff
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose-scheduled.yml down

echo "Temporarilly remove any pre-existing cron entries"
# remove cron entries during build if they exist
croncmd="(cd $PWD && ./cron-civicrm.sh)"
cronjob="*/5 * * * * $croncmd"
( crontab -l | grep -v -F "$croncmd" ) | crontab -

croncmd_back="(cd $PWD && ./cron-backup.sh)"
cronjob_back="6 23 * * * $croncmd_back"
( crontab -l | grep -v -F "$croncmd_back" ) | crontab -

echo "Clean up old docker stuff"
# Clear out any old volumes and DBs
docker container prune -f
docker image prune -f
docker volume prune -f


# generate passwords
echo "Requires pwgen in order to auto-generate secure passwords\n"

export DRUPAL_DB_PASS="$(pwgen -s 20 1)"
export CIVICRM_DB_PASS="$(pwgen -s 20 1)"
export MYSQL_ROOT_PASSWORD="$(pwgen -s 20 1)"

echo "Check ssl certificate permissions"
# certificates require restrictive permissions
chmod 600 traefik/acme.json

echo "Build the base PHP docker image"
# build the base php image
docker build --tag  localhost:5000/php-fpm php-fpm
docker push localhost:5000/php-fpm
echo "Build the base drush image"
docker build --tag  localhost:5000/drush drush
docker push localhost:5000/drush

echo "Build images for restoration"
# docker compose to build
docker-compose -f docker-compose.yml -f docker-compose-restore.yml build

echo "Running duplicity to pull backups from dropbox"
# docker compose to pull backups from dropbox
docker-compose -f docker-compose.yml -f docker-compose-restore.yml run duplicity-restore

echo "Running drush to install Drupal/CiviCRM, and restore all data"
# docker compose to restore from backups
docker-compose -f docker-compose.yml -f docker-compose-restore.yml run drupal-restore

# create scheduled tasks
echo "Creating scheduled tasks for CiviCRM and backups"
( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
( crontab -l | grep -v -F "$croncmd_back" ; echo "$cronjob_back" ) | crontab -

# start everything :-)
docker-compose up -d