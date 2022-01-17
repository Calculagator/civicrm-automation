FROM localhost:5000/php-fpm

# Install the same things I'm using for the drupal container
# I should probably come up with a shared base image for both drupal and drush
# might need mariadb-client for drush installation?
RUN set -ex \
	&& apk add --no-cache mariadb-client gzip

ENV DRUSH_VERSION 8.2.3

COPY ./scripts /scripts
RUN curl -fSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush \
	&& chmod +x /usr/local/bin/drush

WORKDIR /var/www/html