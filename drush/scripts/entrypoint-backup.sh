#!/bin/sh

drush -y cc all

echo "Backup the Drupal DB"
# using gzip with the --rsyncable option should help with incremental backups


drush sql-dump | gzip -5 --rsyncable > /backup/drupal.sql.gz

# same thing with the civicrm db
# --skip-definer would be ideal, but no triggers also works for our use
echo "Backup Civicrm DB"
drush civicrm-sql-dump --extra-options=--skip-triggers | gzip -5 --rsyncable > /backup/civicrm.sql.gz

# backup the upload directories
echo "Backup uploaded files"
tar -cf - sites/default/files/civicrm/custom | gzip --rsyncable > /backup/custom.tar.gz
tar -cf - sites/default/files/civicrm/persist/contribute/files | gzip --rsyncable > /backup/files.tar.gz
tar -cf - sites/default/files/civicrm/persist/contribute/images | gzip --rsyncable > /backup/images.tar.gz

echo " . . . finished!"
