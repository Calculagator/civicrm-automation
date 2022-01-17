#!/bin/bash

# have cron chance to working directory before running this script
# like: cd $DOCKER_ROOT

/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose-scheduled.yml run drupal-scheduled