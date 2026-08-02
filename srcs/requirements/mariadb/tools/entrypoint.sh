#!/bin/sh
set -e

# 1. Read database passwords from Docker secrets.
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
DB_PASSWORD="$(cat /run/secrets/db_password)"

# 2. Stop the container if required secrets are missing.
if [ -z "$DB_ROOT_PASSWORD" ] || [ -z "$DB_PASSWORD" ]; then
	echo "Missing database secrets"
	exit 1
fi

# 3. Stop the container if required environment variables are missing.
if [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ]; then
	echo "Missing MYSQL_DATABASE or MYSQL_USER"
	exit 1
fi

# 4. Create the runtime directory used by the MariaDB socket.
mkdir -p /run/mysqld

# 5. Give the mysql user ownership of runtime and data directories.
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# 6. Initialize MariaDB only if the persistent datadir is still empty.
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "Initializing MariaDB data directory..."

	# 7. Create MariaDB internal system tables inside the datadir.
	mariadb-install-db \
		--user=mysql \
		--datadir=/var/lib/mysql \
		--skip-test-db

	echo "Starting MariaDB setup server..."

	# 8. Start MariaDB in the background so this script can run SQL commands.
	mariadbd \
		--user=mysql \
		--datadir=/var/lib/mysql \
		--socket=/run/mysqld/mysqld.sock \
		--skip-networking=0 &

	MARIADB_PID="$!"

	# 9. Wait until MariaDB is ready to receive commands.
	until mariadb-admin \
		--socket=/run/mysqld/mysqld.sock \
		ping \
		--silent
	do
		echo "Waiting for MariaDB..."
		sleep 1
	done

	echo "Creating database and users..."

	# 10. Configure root, create the WordPress database and create its user.
	mariadb --socket=/run/mysqld/mysqld.sock << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

	# 11. Stop the setup server after the first-time configuration is done.
	mariadb-admin \
		--socket=/run/mysqld/mysqld.sock \
		-u root \
		-p"${DB_ROOT_PASSWORD}" \
		shutdown

	wait "$MARIADB_PID"
fi

echo "Starting MariaDB..."

# 12. Start the final MariaDB server in foreground as the main container process.
exec mariadbd \
	--user=mysql \
	--datadir=/var/lib/mysql \
	--socket=/run/mysqld/mysqld.sock
