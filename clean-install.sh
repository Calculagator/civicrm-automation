#!/bin/bash

#shutdown running stuff
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose-scheduled.yml down

# remove cron entries during build
croncmd="(cd $PWD && ./cron-civicrm.sh)"
cronjob="*/5 * * * * $croncmd"
( crontab -l | grep -v -F "$croncmd" ) | crontab -

croncmd_back="(cd $PWD && ./cron-backup.sh)"
cronjob_back="6 23 * * * $croncmd_back"
( crontab -l | grep -v -F "$croncmd_back" ) | crontab -

# Clear out any old volumes and DBs
docker container prune -f
docker image prune -f
docker volume prune -f


# generate passwords
echo "Requires pwgen in order to auto-generate secure passwords\n"

export DRUPAL_DB_PASS="$(pwgen -s 20 1)"
export CIVICRM_DB_PASS="$(pwgen -s 20 1)"
export MYSQL_ROOT_PASSWORD="$(pwgen -s 20 1)"

# certificates require restrictive permissions
chmod 600 traefik/acme.json


# build the base php image
docker build --tag  localhost:5000/php-fpm php-fpm
docker push localhost:5000/php-fpm
docker build --tag  localhost:5000/drush drush
docker push localhost:5000/drush

# docker compose to build
docker-compose -f docker-compose.yml -f docker-compose-install.yml build

# docker compose to install
docker-compose -f docker-compose.yml -f docker-compose-install.yml run drupal-install

# create scheduled tasks

( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -
( crontab -l | grep -v -F "$croncmd_back" ; echo "$cronjob_back" ) | crontab -