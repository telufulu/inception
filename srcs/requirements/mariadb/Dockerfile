# Instalation Alpine OS
FROM alpine:3.22

# Instalation MariaDB client
RUN apk update && apk add --no-cache mariadb mariadb-client

# Copy custom configurations for MariaDB (following MariaDB's docs)
COPY conf/mariadb.conf /etc/my.cnf.d/mariadb-server.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
