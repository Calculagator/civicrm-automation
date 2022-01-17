#!/bin/sh

echo "scheduled jobs"

# I think this can run without a user
drush -u Administrator civicrm-api job.execute