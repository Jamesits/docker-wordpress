FROM php:apache

RUN a2enmod rewrite expires headers

# install the PHP extensions we need
RUN apt-get update && apt-get upgrade -y && apt-get install -y libpng12-dev libjpeg-dev zlib1g-dev libcurl4-gnutls-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mysqli opcache zip bcmath pdo pdo_mysql curl

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini
	
RUN { \
		echo 'file_uploads=On'; \
		echo 'upload_max_filesize=64M'; \
		echo 'post_max_size=64M'; \
		echo 'max_execution_time=600'; \
	} > /usr/local/etc/php/conf.d/php-recommended.ini

VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.5.3
ENV WORDPRESS_SHA1 835b68748dae5a9d31c059313cd0150f03a49269

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
		echo 'exec php /usr/src/wp-cli/wp-cli.phar --allow-root $@'; \
	} > /usr/bin/wp \
	&& chmod +x /usr/bin/wp \
	&& wp --info

COPY docker-entrypoint.sh /entrypoint.sh

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
