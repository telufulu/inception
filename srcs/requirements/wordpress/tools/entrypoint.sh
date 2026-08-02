#!/bin/sh
set -e

# Read passwords from Docker secrets
DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

# Stop the container if required secrets are missing
if [ -z "$DB_PASSWORD" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_USER_PASSWORD" ]; then
	echo "Missing WordPress or database secrets"
	exit 1

fi

# Stop the container if required environment variables are missing
if [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$DOMAIN_NAME" ]; then
	echo "Missing database or domain environment variables"
	exit 1
fi

if [ -z "$WP_TITLE" ] || [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
	echo "Missing WordPress administrator environment variables"
	exit 1
fi

if [ -z "$WP_USER" ] || [ -z "$WP_USER_EMAIL" ]; then
	echo "Missing WordPress regular user environment variables"
	exit 1
fi

# Avoid the warning because is not a petition from a real web
export HTTP_HOST="$DOMAIN_NAME"

# Prepare the WordPress directory mounted from the persistent volume
mkdir -p /var/www/html
cd /var/www/html

# Download WP-CLI if it is not already available
if [ ! -f /usr/local/bin/wp ]; then
	echo "Installing WP-CLI..."

	curl -fsSL \
		-o /usr/local/bin/wp \
		https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

	chmod +x /usr/local/bin/wp
fi

# Wait until MariaDB accepts connections through the Docker network
until mariadb \
	-h mariadb \
	-u "$MYSQL_USER" \
	-p"$DB_PASSWORD" \
	"$MYSQL_DATABASE" \
	-e "SELECT 1;" >/dev/null 2>&1
do
	echo "Waiting for MariaDB..."
	sleep 1
done

# Download WordPress core files only if they are not already in the volume
if [ ! -f /var/www/html/wp-load.php ]; then
	echo "Downloading WordPress core..."

	wp core download \
		--allow-root \
		--path=/var/www/html
fi

# Create wp-config.php only if it does not already exist
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "Creating WordPress configuration..."

	wp config create \
		--allow-root \
		--path=/var/www/html \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$DB_PASSWORD" \
		--dbhost="mariadb:3306"
fi

# Install WordPress only if it is not already installed
if ! wp core is-installed --allow-root --path=/var/www/html; then
	echo "Installing WordPress..."

	wp core install \
		--allow-root \
		--path=/var/www/html \
		--url="https://${DOMAIN_NAME}" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL"

	echo "Creating regular WordPress user..."

	wp user create \
		"$WP_USER" \
		"$WP_USER_EMAIL" \
		--allow-root \
		--path=/var/www/html \
		--user_pass="$WP_USER_PASSWORD" \
		--role=author
fi

# Give PHP-FPM ownership of the persistent WordPress files
chown -R nobody:nobody /var/www/html

# Start PHP-FPM in foreground as the main container process
exec php-fpm84 -F
