# User documentation

## What this stack provides

This project runs a small WordPress website infrastructure using Docker Compose.

The stack contains three services:

- NGINX: receives HTTPS requests from the browser on port 443
- WordPress + PHP-FPM: runs the WordPress application
- MariaDB: stores the WordPress database

The request flow is:

```text
Browser
↓ HTTPS 443
NGINX
↓ FastCGI
WordPress + PHP-FPM
↓ SQL
MariaDB
```

Only NGINX is exposed to the host. WordPress and MariaDB are internal services and are only reachable through the Docker network.

## How to start the project

Run the project from the root of the repository:

```bash
make
```

or:

```bash
make up
```

This command creates the persistent data directories and starts the Docker Compose stack.

Expected containers:

```text
inception-nginx
inception-wordpress
inception-mariadb
```

## How to stop the project

To stop the containers without deleting persistent data:

```bash
make down
```

To rebuild everything from scratch:

```bash
make re
```

To remove containers, images, volumes and project data:

```bash
make fclean
```

Use `make fclean` carefully because it removes the persistent WordPress and MariaDB data stored under `/home/<login>/data`.

## How to access the website

The website is available through HTTPS:

```text
https://telufulu.42.fr
```

The domain must resolve to the virtual machine.

Inside the VM, `/etc/hosts` can contain:

```text
127.0.0.1 telufulu.42.fr
```

From a host machine, `/etc/hosts` should point the domain to the VM IP:

```text
VM_IP telufulu.42.fr
```

The certificate is self-signed, so the browser may show a security warning. This is expected for this project.

You can test HTTPS with:

```bash
curl -k -I https://telufulu.42.fr
```

## How to access the administration panel

The WordPress administration panel is available at:

```text
https://telufulu.42.fr/wp-admin
```

Use the WordPress administrator credentials defined through the project secrets and environment configuration.

## Credentials

Sensitive credentials are stored in the `secrets/` directory at the root of the repository:

```text
secrets/
├── db_root_password
├── db_password
├── wp_admin_password
└── wp_user_password
```

Each file contains one password.

The containers read these files through Docker secrets from:

```text
/run/secrets/<secret_name>
```

Non-sensitive configuration is stored in:

```text
srcs/.env
```

Examples of non-sensitive values:

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

Passwords must not be written in Dockerfiles or committed to the repository.

## How to check that services are running

List running containers:

```bash
docker ps
```

Expected result:

```text
inception-nginx
inception-wordpress
inception-mariadb
```

Check Compose status:

```bash
docker compose -f srcs/docker-compose.yml -p inception ps
```

Check NGINX:

```bash
docker exec -it inception-nginx nginx -t
curl -k -I https://telufulu.42.fr
```

Check WordPress files:

```bash
docker exec -it inception-wordpress sh
ls -la /var/www/html
```

Expected files include:

```text
wp-config.php
wp-load.php
wp-admin
wp-content
wp-includes
```

Check MariaDB:

```bash
docker exec -it inception-mariadb sh
mariadb -u wp_user -p wordpress
```

Check logs:

```bash
docker logs inception-nginx
docker logs inception-wordpress
docker logs inception-mariadb
```

## Troubleshooting

If the browser cannot reach the website:

- Check that the containers are running with `docker ps`
- Check that NGINX publishes port 443
- Check that the domain resolves to the VM
- Check HTTPS with `curl -k -I https://telufulu.42.fr`
- Check NGINX logs with `docker logs inception-nginx`

If WordPress redirects to another URL, verify the WordPress `home` and `siteurl` options.

If MariaDB or WordPress fails at startup, check the related logs:

```bash
docker logs inception-mariadb
docker logs inception-wordpress
```
