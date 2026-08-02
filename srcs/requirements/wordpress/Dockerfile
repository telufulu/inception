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

# Configure PHP-FPM
COPY conf/www.conf /etc/php84/php-fpm.d/www.conf

# Copy the WordPress startup script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the startup script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Run the startup script when the container starts
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
