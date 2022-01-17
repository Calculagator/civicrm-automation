#!/bin/bash

# have cron change to working directory before running this script
# like: cd $DOCKER_ROOT


/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose-scheduled.yml run drupal-backup

# launch duplicity to send incremental backups to dropbox

/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose-scheduled.yml run duplicity-backup


# cleanup docker unused containers

docker container prune -f
# docker volume prune -f # like to keep the duplicity one?
docker image prune -f
