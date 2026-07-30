#!/bin/sh

# Colors
RESET="\033[0m"

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"

# Summary lists
SUCCESS_LIST=""
FAILED_LIST=""

# Helpers
section()
{
	printf "\n${MAGENTA}/********************/\n"
	printf "%s\n" "$1"
	printf "/********************/${RESET}\n\n"
}

step()
{
	printf "${CYAN}==== %s ====${RESET}\n" "$1"
}

add_success()
{
	SUCCESS_LIST="${SUCCESS_LIST}
- $1"
}

add_failed()
{
	FAILED_LIST="${FAILED_LIST}
- $1"
}

run_step()
{
	DESCRIPTION="$1"
	shift

	step "$DESCRIPTION"

	if "$@"; then
		printf "${GREEN}%s ✅${RESET}\n\n" "$DESCRIPTION"
		add_success "$DESCRIPTION"
		return 0
	else
		printf "${RED}%s ❌${RESET}\n\n" "$DESCRIPTION"
		add_failed "$DESCRIPTION"
		return 1
	fi
}

# Check root
if [ "$(id -u)" -ne 0 ]; then
	printf "${RED}This script must be run as root.${RESET}\n"
	printf "Try:\n"
	printf "  su -\n"
	printf "or:\n"
	printf "  sudo ./setup-vm.sh\n"
	exit 1
fi

section "INSTALLATIONS"

run_step "Updating APT package list" apt update
run_step "Upgrading system packages" apt upgrade -y

run_step "Installing sudo" apt install -y sudo
run_step "Installing vim" apt install -y vim
run_step "Installing make" apt install -y make
run_step "Installing curl, ca-certificates and gnupg" apt install -y curl ca-certificates gnupg

step "Creating root vim configuration"

if cat > /root/.vimrc << EOF
syntax on
set nu
set rnu
EOF
then
	printf "${GREEN}/root/.vimrc created ✅${RESET}\n\n"
	add_success "/root/.vimrc created"
else
	printf "${RED}/root/.vimrc creation failed ❌${RESET}\n\n"
	add_failed "/root/.vimrc creation failed"
fi

section "DOCKER INSTALLATION"

run_step "Creating Docker keyrings directory" install -m 0755 -d /etc/apt/keyrings

step "Downloading Docker GPG key"

if curl -fsSL https://download.docker.com/linux/debian/gpg \
	| gpg --dearmor -o /etc/apt/keyrings/docker.gpg
then
	printf "${GREEN}Docker GPG key downloaded ✅${RESET}\n\n"
	add_success "Docker GPG key downloaded"
else
	printf "${RED}Docker GPG key download failed ❌${RESET}\n\n"
	add_failed "Docker GPG key download failed"
fi

run_step "Setting Docker GPG key permissions" chmod a+r /etc/apt/keyrings/docker.gpg

step "Adding Docker APT repository"

if echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
	> /etc/apt/sources.list.d/docker.list
then
	printf "${GREEN}Docker APT repository added ✅${RESET}\n\n"
	add_success "Docker APT repository added"
else
	printf "${RED}Docker APT repository failed ❌${RESET}\n\n"
	add_failed "Docker APT repository failed"
fi

run_step "Updating APT after adding Docker repository" apt update

run_step "Installing Docker packages" apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

step "Checking Docker version"

if docker --version; then
	printf "${GREEN}Docker command works ✅${RESET}\n\n"
	add_success "Docker command works"
else
	printf "${RED}Docker command failed ❌${RESET}\n\n"
	add_failed "Docker command failed"
fi

step "Checking Docker Compose version"

if docker compose version; then
	printf "${GREEN}Docker Compose command works ✅${RESET}\n\n"
	add_success "Docker Compose command works"
else
	printf "${RED}Docker Compose command failed ❌${RESET}\n\n"
	add_failed "Docker Compose command failed"
fi

section "CONFIGURATIONS"

step "Configuring main user"

printf "Please, enter the main user: "
read LOGIN
LOGIN = ${YELLOW}${LOGIN}${RESET}

if [ -z "$LOGIN" ]; then
	printf "${RED}Empty user input ❌${RESET}\n\n"
	add_failed "Main user configuration: empty user input"
else
	if id "$LOGIN" >/dev/null 2>&1; then
		if usermod -aG sudo "$LOGIN"; then
			printf "%s added to sudo group ✅${RESET}\n" "$$LOGIN"
			add_success "$LOGIN added to sudo group"
		else
			printf "${RED}Could not add %s${RED} to sudo group ❌${RESET}\n" "$LOGIN"
			add_failed "$LOGIN added to sudo group"
		fi

		if usermod -aG docker "$LOGIN"; then
			printf "${GREEN}%s added to docker group ✅${RESET}\n" "$LOGIN"
			add_success "$LOGIN added to docker group"
		else
			printf "${RED}Could not add %s ${RED}to docker group ❌${RESET}\n" "$LOGIN"
			add_failed "$LOGIN added to docker group"
		fi

		step "Creating user vim configuration"

		if cat > "/home/$LOGIN/.vimrc" << EOF
syntax on
set nu
set rnu
EOF
		then
			if chown "$LOGIN:$LOGIN" "/home/$LOGIN/.vimrc"; then
				printf "${GREEN}/home/%s/.vimrc created ✅${RESET}\n\n" "$LOGIN"
				add_success "/home/$LOGIN/.vimrc created"
			else
				printf "${RED}/home/%s/.vimrc ownership failed ❌${RESET}\n\n" "$LOGIN"
				add_failed "/home/$LOGIN/.vimrc ownership failed"
			fi
		else
			printf "${RED}/home/%s/.vimrc creation failed ❌${RESET}\n\n" "$LOGIN"
			add_failed "/home/$LOGIN/.vimrc creation failed"
		fi
	else
		printf "${RED}User does not exist: %s ❌${RESET}\n\n" "$LOGIN"
		add_failed "Main user does not exist: $LOGIN"
	fi
fi

section "SUMMARY"

printf "${GREEN}Successful steps:${RESET}\n"

if [ -n "$SUCCESS_LIST" ]; then
	printf "%s\n" "$SUCCESS_LIST"
else
	printf "%s\n" "- None"
fi

printf "\n${RED}Failed steps:${RESET}\n"

if [ -n "$FAILED_LIST" ]; then
	printf "%s\n" "$FAILED_LIST"
else
	printf "%s\n" "- None"
fi

printf "\n"

if [ -n "$FAILED_LIST" ]; then
	printf "${YELLOW}Some steps failed. Review the failed list above before continuing.${RESET}\n"
else
	printf "${GREEN}✅ All done successfully!${RESET}\n"
fi

printf "\n${YELLOW}Important:${RESET} log out and log in again so docker group changes apply.\n"
printf "Then try:\n"
printf "  docker ps\n"
