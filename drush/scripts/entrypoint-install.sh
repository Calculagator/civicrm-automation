#!/bin/sh

# drush likes to both require a root folder and name it with a version. I would prefer neither of those
# this works around that by making ./html the root

drush -y dl drupal-7 --destination=/var/www --drupal-project-rename=html

# drush site-install

# wait for the database
# this should probably be something smarter . . .
sleep 20s

drush -y si standard --site-name="$SITE_NAME" --site-mail=$FROM_EMAIL --account-mail=$ADMIN_EMAIL --account-name=$DRUPAL_ADMIN --account-pass=$DRUPAL_ADMIN_PASS --db-url=mysql://$DRUPAL_DB_USER:$DRUPAL_DB_PASS@mysql/$DRUPAL_DB --db-su=root --db-su-pw=$MYSQL_ROOT_PASSWORD

drush status

# fix php trying to make http links
# echo "\$conf['reverse_proxy'] = TRUE;
#\$conf['reverse_proxy_addresses'] = array(\$proxy_ip);}" >> /var/www/html/sites/default/settings.php

# enable the theme we will use
drush -y dl adaptivetheme
drush -y en adaptivetheme_admin
drush vset theme_default adaptivetheme_admin
drush vset admin_theme adaptivetheme_admin
drush -y en adminrole
drush -y en smtp
drush -y en flood_control
# I don't like the overlay
drush -y dis overlay
drush -y pmu overlay

# I do like the toolbar
drush -y en toolbar

# themes throw fewer errors about missing files with aggregation maybe?
drush  -y vset preprocess_css 1
drush -y vset preprocess_js 1

# download civicrm and extract it to the modules directory
curl -o civicrm.tar.gz -L https://download.civicrm.org/civicrm-$CIVICRM_VERSION-drupal.tar.gz
tar -xzf civicrm.tar.gz -C /var/www/html/sites/all/modules
rm civicrm.tar.gz

# use drush to create civicrm DB
drush -y sql-create --db-su=root --db-su-pw=$MYSQL_ROOT_PASSWORD --db-url="mysql://$CIVICRM_DB_USER:$CIVICRM_DB_PASS@mysql/$CIVICRM_DB"

# set upload directory writeable
chmod -R 777 /var/www/html/sites/default/files
#fix permissions for civicrm install
chmod 755 /var/www/html/sites/default

# use drush to install civicrm
drush --include=sites/all/modules/civicrm/drupal/drush civicrm-install --dbhost=mysql --dbname=$CIVICRM_DB --dbpass=$CIVICRM_DB_PASS --dbuser=$CIVICRM_DB_USER --destination=sites/all/modules --site_url=$SITE_URL 

# set civicrm permissions after install?
chown -R www-data:www-data /var/www/html