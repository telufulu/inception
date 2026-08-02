_This project has been created as part of the 42 curriculum by [telufulu](https://profile.intra.42.fr/users/telufulu)_

# Inception (42 Project)

## Table of Contents

- [Description](#description)
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Compilation](#compilation)
- [Usage](#usage)
- [Features](#features)
- [Project Structure](#project-structure)
- [Known Limitations](#known-limitations)
- [Resources](#resources)
- [AI Usage Disclosure](#ai-usage-disclosure)
- [Credits](#credits)
- [Academic Integrity Notice](#academic-integrity-notice)
- [License](#license)

## Description

Inception is a Docker-based system administration project from the 42 curriculum. The goal is to deploy a small web infrastructure inside a virtual machine using Docker Compose.

This repository builds a LEMP-style stack composed of three independent services:

- **NGINX** as the only public entry point, listening on HTTPS port `443`
- **WordPress with PHP-FPM** as the web application runtime
- **MariaDB** as the internal database service used by WordPress

Each service is built from its own Dockerfile using `alpine:3.22` as the base image. The project avoids prebuilt service images such as official `nginx`, `wordpress`, or `mariadb` images. Containers communicate through a custom Docker bridge network, while WordPress and MariaDB data are persisted through named volumes mapped to `/home/<login>/data`.

The expected request flow is:

    User
      ↓ HTTPS 443
    NGINX
      ↓ FastCGI
    WordPress + PHP-FPM
      ↓ SQL
    MariaDB

## Installation

### Requirements

This project is intended to run inside a Linux virtual machine, as required by the Inception subject.

Required tools inside the VM:

- Debian or another Linux-based system
- Docker Engine
- Docker Compose plugin
- make
- git
- sudo permissions for setup and cleanup tasks

Check the required tools:

    docker --version
    docker compose version
    make --version
    git --version

The project uses the local domain:

    telufulu.42.fr

Inside the VM, this domain can be mapped to localhost because NGINX publishes port `443` on the VM:

    127.0.0.1 telufulu.42.fr

If accessing the site from the physical host machine, map the domain to the VM IP instead:

    <VM_IP> telufulu.42.fr

### Compilation

From the repository root, build and start the infrastructure with:

    make

or:

    make up

The Makefile runs Docker Compose with:

    docker compose -f srcs/docker-compose.yml -p inception up --build

It also creates the persistent data directories before starting the stack:

    /home/<login>/data/wordpress
    /home/<login>/data/mariadb

Available Makefile rules:

    make
    make up
    make down
    make logs
    make ps
    make clean
    make fclean
    make re

Rule summary:

- `make` / `make up` — create data directories, build images, and start the containers
- `make down` — stop and remove the Compose containers and network without deleting persisted data
- `make logs` — follow service logs
- `make ps` — show Compose service status
- `make clean` — alias for `make down`
- `make fclean` — remove Compose containers, images, volumes, and project data directories
- `make re` — clean everything and rebuild from scratch

## Usage

Start the infrastructure:

    make

Check the running containers:

    docker ps

Expected containers:

    inception-nginx
    inception-wordpress
    inception-mariadb

Open the WordPress site:

    https://telufulu.42.fr

Because the TLS certificate is self-signed, browsers may show a certificate warning. This is expected for this project.

Check HTTPS from the terminal:

    curl -k -I https://telufulu.42.fr

Check NGINX configuration:

    docker exec -it inception-nginx nginx -t

Follow logs:

    make logs

or per container:

    docker logs inception-nginx
    docker logs inception-wordpress
    docker logs inception-mariadb

Stop the stack:

    make down

Rebuild from scratch:

    make re

## Features

- Multi-container infrastructure managed with Docker Compose
- Custom Dockerfile for each required service
- Alpine Linux `3.22` used as the base image
- NGINX configured as the only public entry point
- HTTPS enabled on port `443` with a self-signed certificate
- TLS restricted to `TLSv1.2` and `TLSv1.3`
- WordPress served through PHP-FPM on the internal port `9000`
- MariaDB available only inside the Docker network on port `3306`
- Custom Docker bridge network named `inception-net`
- Named volume for WordPress data
- Named volume for MariaDB data
- Persistent data stored under `/home/<login>/data`
- Docker secrets used for passwords
- `.env` file used for non-sensitive configuration
- MariaDB initialized automatically on first container startup
- WordPress downloaded, configured, and installed automatically through WP-CLI
- Restart policy configured with `restart: unless-stopped`
- Helper VM setup script included as `configVM.sh`

## Project Structure

    .
    ├── LICENSE
    ├── Makefile
    ├── README.md
    ├── configVM.sh
    ├── secrets/
    │   ├── db_password
    │   ├── db_password.example
    │   ├── db_root_password
    │   ├── db_root_password.example
    │   ├── wp_admin_password
    │   ├── wp_admin_password.example
    │   ├── wp_user_password
    │   └── wp_user_password.example
    └── srcs/
        ├── .env
        ├── docker-compose.yml
        └── requirements/
            ├── mariadb/
            │   ├── .dockerignore
            │   ├── Dockerfile
            │   ├── conf/
            │   │   └── mariadb.conf
            │   └── tools/
            │       └── entrypoint.sh
            ├── nginx/
            │   ├── .dockerignore
            │   ├── Dockerfile
            │   └── conf/
            │       └── nginx.conf
            └── wordpress/
                ├── .dockerignore
                ├── Dockerfile
                ├── conf/
                │   ├── wordpress.conf
                │   └── www.conf
                └── tools/
                    └── entrypoint.sh

Main files:

- `Makefile` — central entry point for building, starting, stopping, and cleaning the project
- `srcs/docker-compose.yml` — defines services, network, volumes, and secrets
- `srcs/.env` — stores non-sensitive runtime configuration
- `secrets/` — stores password files used as Docker secrets
- `configVM.sh` — helper script to prepare a Debian VM with Docker and related tools

## Known Limitations

- The project is designed for local evaluation, not for production deployment
- The TLS certificate is self-signed and will not be trusted by browsers by default
- The domain `telufulu.42.fr` is resolved locally through `/etc/hosts`, not through public DNS
- The stack does not include a mail server, so WordPress installation emails may fail to send
- The project only exposes NGINX on port `443`; WordPress/PHP-FPM and MariaDB are intentionally not reachable from the host
- Bonus services are not included in this base setup

## Resources

### Official Documentation

- Docker Engine installation on Debian — https://docs.docker.com/engine/install/debian/
- Docker Compose file reference — https://docs.docker.com/reference/compose-file/
- Docker Compose secrets — https://docs.docker.com/compose/how-tos/use-secrets/
- Docker volumes — https://docs.docker.com/engine/storage/volumes/
- NGINX HTTPS servers — https://nginx.org/en/docs/http/configuring_https_servers.html
- MariaDB server documentation — https://mariadb.com/docs/server/
- MariaDB Docker usage — https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/installing-and-using-mariadb-via-docker
- PHP-FPM configuration — https://www.php.net/manual/en/install.fpm.configuration.php
- WP-CLI handbook — https://make.wordpress.org/cli/handbook/
- WP-CLI `core download` — https://developer.wordpress.org/cli/commands/core/download/
- WP-CLI `config create` — https://developer.wordpress.org/cli/commands/config/create/
- WP-CLI `core install` — https://developer.wordpress.org/cli/commands/core/install/
- WP-CLI `user create` — https://developer.wordpress.org/cli/commands/user/create/
- Alpine packages — https://pkgs.alpinelinux.org/packages

### README Guidelines

- How to Write a Good README – freeCodeCamp — https://www.freecodecamp.org/news/how-to-write-a-good-readme-file/
- Make a README — https://www.makeareadme.com/
- Choose a license — https://choosealicense.com/

## AI Usage Disclosure

AI tools were used to help review, clean up, and organize shell scripts and project documentation so the structure remained consistent and easier to verify. They were also used to clarify Docker, NGINX, MariaDB, WordPress, PHP-FPM, TLS, volumes, and networking concepts during the learning process.

The original implementation, architecture decisions, service configuration, and project logic were written and reviewed manually by the author.

## Credits

- telufulu
  - 42 profile: https://profile.intra.42.fr/users/telufulu
  - GitHub: https://github.com/telufulu
  - LinkedIn: https://www.linkedin.com/in/teresa-b-lufuluabo-pastor-659702204/

## Academic Integrity Notice

> This repository is published for educational purposes only.
> Submitting this work as your own in academic evaluations constitutes academic misconduct.

## License

This project is licensed under the MIT License — see the `LICENSE` file for details.
