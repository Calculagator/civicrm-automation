#!/bin/sh

# I think I'm using an external script for now to copy over all of the db and upload files.
# This entrypoint needs to run the sql files to poplulate the respective drupal and civicrm databases
# it should then process any db upgrades necessary

drush status


# use drush to import drupal.sql
echo "import the drupal db"
gunzip -c /backup/drupal.sql.gz | drush sqlc 

# use drush to import civicrm
echo "import the civicrm db"
gunzip -c /backup/civicrm.sql.gz | drush cvsqlc

# unpack the transferred uploads (should have directory intact for drupal root)
echo "import the uploads"
tar -xf /backup/images.tar.gz 
tar -xf /backup/files.tar.gz 
tar -xf /backup/custom.tar.gz 

# run the DB upgrades
echo "run the drupal db updates"
drush updb
echo "run the civicrm db updates"
drush cvupdb

# ? revert all features (might install what we need?)

echo "set the adaptivetheme to the default?"
drush vset theme_default adaptivetheme_admin
drush vset admin_theme adaptivetheme_admin

# fix any webroot permissions changed by drush
echo "web user owns the webroot"
chown -R www-data:www-data /var/www/html

echo "clear the cache"
drush -y cc all

echo "Finished moving"