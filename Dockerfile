FROM php:apache

RUN a2enmod rewrite expires headers substitute remoteip

# install the PHP extensions we need
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y libpng-dev libjpeg-dev zlib1g-dev libcurl4-gnutls-dev libldb-dev libldap-2.4-2 libldap2-dev libmcrypt-dev less sudo\
	&& rm -rf /var/lib/apt/lists/* \
	&& ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
	&& ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mysqli opcache zip bcmath pdo pdo_mysql curl mbstring ldap
# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
	
RUN { \
		echo 'file_uploads=On'; \
		echo 'upload_max_filesize=256M'; \
		echo 'post_max_size=256M'; \
		echo 'max_execution_time=1200'; \
	} > /usr/local/etc/php/conf.d/php-recommended.ini

VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.7.5
ENV WORDPRESS_SHA1 fbe0ee1d9010265be200fe50b86f341587187302

# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data /usr/src/wordpress
	
# install wp-cli from https://wp-cli.org/
RUN curl -SLO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& mkdir -p /usr/src/wp-cli \
	&& mv wp-cli.phar /usr/src/wp-cli/ \
	&& chmod +x /usr/src/wp-cli/wp-cli.phar
RUN { \
		echo '#!/bin/bash'; \
		echo 'cd ${WORDPRESS_ROOT:-/var/www/html/}'; \
		echo 'exec sudo -u www-data -s -- php /usr/src/wp-cli/wp-cli.phar $@'; \
	} > /usr/bin/wp \
	&& chmod +x /usr/bin/wp \
	&& wp --info

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
