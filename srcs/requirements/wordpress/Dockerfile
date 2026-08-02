# Instalation Alpine OS
FROM alpine:3.22

# Install PHP-FPM, PHP extensions, MariaDB client and download tools
RUN apk update && apk add --no-cache \
	php84 \
	php84-fpm \
	php84-mysqli \
	php84-phar \
	php84-curl \
	php84-mbstring \
	php84-session \
	php84-json \
	mariadb-client \
	curl \
	tar
# In case wordpress look for php instead php84, I create a link name php to php84
RUN ln -s /usr/bin/php84 /usr/bin/php

# Sometime I have an error limit. Force to have more limit for php
RUN echo "memory_limit = 256M" > /etc/php84/conf.d/99-memory-limit.ini

# Configure PHP-FPM
COPY conf/www.conf /etc/php84/php-fpm.d/www.conf

# Copy the WordPress startup script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the startup script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run the startup script when the container starts
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
