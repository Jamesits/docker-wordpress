FROM jamesits/easyphp:latest
LABEL maintainer="docker@public.swineson.me"

VOLUME /var/www/html

ARG WORDPRESS_VERSION=4.9.7
ARG WORDPRESS_SHA1=7bf349133750618e388e7a447bc9cdc405967b7d

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
# backwards compat
RUN rm -f /entrypoint.sh \
	&& ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
