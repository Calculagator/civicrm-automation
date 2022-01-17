#!/bin/sh

# drush likes to both require a root folder and name it with a version. 
# I would prefer neither of those
# this works around that by making ./html the root

echo "Download Drupal $DRUPAL_VERSION"
drush -y dl drupal-$DRUPAL_VERSION --destination=/var/www --drupal-project-rename=html

# drush site-install

# wait for the database

while ! mysqladmin ping -h"mysql" --silent; do
    sleep 1
done

# a few extra wait seconds for good measure
sleep 3s

echo "Install Drupal $DRUPAL_VERSION"
drush -y si standard --site-name="$SITE_NAME" --site-mail=$FROM_EMAIL --account-mail=$ADMIN_EMAIL --account-name=$DRUPAL_ADMIN --account-pass=$DRUPAL_ADMIN_PASS --db-url=mysql://$DRUPAL_DB_USER:$DRUPAL_DB_PASS@mysql/$DRUPAL_DB --db-su=root --db-su-pw=$MYSQL_ROOT_PASSWORD

drush status

echo "Set default themes and modules"
# enable the theme we will use
drush -y dl adaptivetheme
drush -y en adaptivetheme_admin
drush vset theme_default adaptivetheme_admin
drush vset admin_theme adaptivetheme_admin
drush -y en adminrole
drush -y en smtp
drush -y en flood_control
drush -y en variablecheck

# I don't like the overlay
drush -y dis overlay
drush -y pmu overlay

# I do like the toolbar
drush -y en toolbar

# themes throw fewer errors about missing files with aggregation maybe?
drush  -y vset preprocess_css 1
drush -y vset preprocess_js 1

# download civicrm and extract it to the modules directory
echo "Download and extract CiviCRM"
curl -o civicrm.tar.gz -L https://download.civicrm.org/civicrm-$CIVICRM_VERSION-drupal.tar.gz
tar -xzf civicrm.tar.gz -C /var/www/html/sites/all/modules
rm civicrm.tar.gz

# use drush to create civicrm DB
echo "Create CiviCRM DB"
drush -y sql-create --db-su=root --db-su-pw=$MYSQL_ROOT_PASSWORD --db-url="mysql://$CIVICRM_DB_USER:$CIVICRM_DB_PASS@mysql/$CIVICRM_DB"

# set upload directory writeable
echo "Fix Permissions"
chmod -R 777 /var/www/html/sites/default/files
#fix permissions for civicrm install
chmod 755 /var/www/html/sites/default

# use drush to install civicrm
echo "Install CiviCRM"
drush --include=sites/all/modules/civicrm/drupal/drush civicrm-install --dbhost=mysql --dbname=$CIVICRM_DB --dbpass=$CIVICRM_DB_PASS --dbuser=$CIVICRM_DB_USER --destination=sites/all/modules --site_url=$SITE_URL 

# set civicrm permissions after install?
chown -R www-data:www-data /var/www/html

drush -y cc all

# use drush to import drupal.sql
echo "import the drupal db"
gunzip -c /backup/drupal.sql.gz | drush sqlc 

# use drush to import civicrm
echo "import the civicrm db"
gunzip -c /backup/civicrm.sql.gz | drush cvsqlc

# unpack the transferred uploads (should have directories intact from drupal root directory)
echo "import the uploads"
tar -xf /backup/images.tar.gz 
tar -xf /backup/files.tar.gz 
tar -xf /backup/custom.tar.gz 

# run the DB upgrades
echo "run the drupal db updates"
drush updb
echo "run the civicrm db updates"
drush cvupdb

drush -y cc all

# set civicrm permissions after install?
chown -R www-data:www-data /var/www/html

echo "Finished Restore"