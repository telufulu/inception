# Developer documentation

## Repository structure

Recommended project structure:

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── db_root_password
│   ├── db_password
│   ├── wp_admin_password
│   └── wp_user_password
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       └── entrypoint.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            │   └── mariadb.conf
            └── tools/
                └── entrypoint.sh
```

## Services

The project contains three Docker Compose services:

- `nginx`: HTTPS entry point
- `wordpress`: WordPress application running with PHP-FPM
- `mariadb`: database server used by WordPress

The internal flow is:

```text
nginx → wordpress:9000
wordpress → mariadb:3306
```

Only NGINX publishes a port to the host:

```yaml
ports:
  - "443:443"
```

WordPress and MariaDB must not publish ports to the host.

## Prerequisites

The project must run inside a virtual machine.

Required tools inside the VM:

- Docker
- Docker Compose plugin
- Make
- Git

Check them with:

```bash
docker --version
docker compose version
make --version
git --version
```

The user should be in the `docker` group so Docker can run without `sudo`:

```bash
groups
docker ps
```

## Environment configuration

Create the environment file:

```text
srcs/.env
```

Example:

```text
LOGIN=telufulu
DOMAIN_NAME=telufulu.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

WP_TITLE=Inception
WP_ADMIN_USER=owner
WP_ADMIN_EMAIL=owner@telufulu.42.fr
WP_USER=user
WP_USER_EMAIL=user@telufulu.42.fr
```

The `.env` file should contain non-sensitive configuration only.

## Secrets

Create the secrets directory at the root of the repository:

```text
secrets/
```

Required files:

```text
secrets/db_root_password
secrets/db_password
secrets/wp_admin_password
secrets/wp_user_password
```

Each file must contain only one password.

Example:

```bash
mkdir -p secrets
printf "root_password_here\n" > secrets/db_root_password
printf "db_password_here\n" > secrets/db_password
printf "wp_admin_password_here\n" > secrets/wp_admin_password
printf "wp_user_password_here\n" > secrets/wp_user_password
```

Do not store real passwords in Dockerfiles, shell scripts or committed documentation.

Recommended `.gitignore` entries:

```text
secrets/
*.key
*.pem
.env.local
```

## Build and launch

From the repository root:

```bash
make
```

or:

```bash
make up
```

The Makefile should create the persistent directories before launching Docker Compose:

```text
/home/<login>/data/wordpress
/home/<login>/data/mariadb
```

Docker Compose command used by the Makefile:

```bash
docker compose -f srcs/docker-compose.yml -p inception up --build
```

## Stop and clean

Stop containers without deleting data:

```bash
make down
```

Show logs:

```bash
make logs
```

Show container status:

```bash
make ps
```

Remove containers, images, volumes and persistent project data:

```bash
make fclean
```

Rebuild from scratch:

```bash
make re
```

## Container management commands

List containers:

```bash
docker ps
docker ps -a
```

View logs:

```bash
docker logs inception-nginx
docker logs inception-wordpress
docker logs inception-mariadb
```

Enter containers:

```bash
docker exec -it inception-nginx sh
docker exec -it inception-wordpress sh
docker exec -it inception-mariadb sh
```

Validate NGINX configuration:

```bash
docker exec -it inception-nginx nginx -t
```

Check WordPress files:

```bash
docker exec -it inception-wordpress ls -la /var/www/html
```

Connect to MariaDB:

```bash
docker exec -it inception-mariadb sh
mariadb -u wp_user -p wordpress
```

## Volume management commands

List volumes:

```bash
docker volume ls
```

Inspect project volumes:

```bash
docker volume inspect wordpress_data
docker volume inspect mariadb_data
```

Expected physical paths:

```text
/home/telufulu/data/wordpress
/home/telufulu/data/mariadb
```

## Network management commands

List networks:

```bash
docker network ls
```

Inspect the project network:

```bash
docker network inspect inception-net
```

Expected containers in the network:

```text
inception-nginx
inception-wordpress
inception-mariadb
```

The project must use a custom bridge network and must not use:

```yaml
network_mode: host
links:
```

## Data persistence

The project uses two named volumes:

- `wordpress_data`: stores WordPress files
- `mariadb_data`: stores MariaDB data

Inside the containers:

```text
wordpress_data → /var/www/html
mariadb_data   → /var/lib/mysql
```

On the VM host:

```text
wordpress_data → /home/telufulu/data/wordpress
mariadb_data   → /home/telufulu/data/mariadb
```

The volumes are declared as named volumes with `driver_opts` so Docker can manage them by name while the data is physically stored under `/home/<login>/data`.

This allows data to survive container recreation.

To test persistence:

1. Start the project
2. Create content in WordPress
3. Stop the project with `make down`
4. Start it again with `make`
5. Check that the content still exists

## HTTPS and domain checks

The project should be reachable at:

```text
https://telufulu.42.fr
```

Check HTTPS:

```bash
curl -k -I https://telufulu.42.fr
```

Check TLS versions:

```bash
openssl s_client -connect telufulu.42.fr:443 -tls1_2
openssl s_client -connect telufulu.42.fr:443 -tls1_3
openssl s_client -connect telufulu.42.fr:443 -tls1
```

TLSv1.2 and TLSv1.3 should work. TLSv1 should fail or not negotiate correctly.

## Debugging checklist

If the project does not start:

```bash
docker compose -f srcs/docker-compose.yml -p inception ps
docker logs inception-mariadb
docker logs inception-wordpress
docker logs inception-nginx
```

If NGINX fails:

```bash
docker exec -it inception-nginx nginx -t
docker logs inception-nginx
```

If WordPress cannot connect to the database:

```bash
docker logs inception-wordpress
docker logs inception-mariadb
docker exec -it inception-wordpress sh
mariadb -h mariadb -u wp_user -p wordpress
```

If data disappears after restart:

```bash
docker volume ls
docker volume inspect wordpress_data
docker volume inspect mariadb_data
ls -la /home/telufulu/data
```

## Reset procedure

To reset only running containers while keeping data:

```bash
make down
make
```

To reset everything, including persistent data:

```bash
make fclean
make
```

Use the full reset only when the stored WordPress and MariaDB data can be deleted.
