#!/bin/sh
# This script follows the structure from the notes in Notion (https://app.notion.com/p/teresalufuluabo/Inception-1db81b4ca7b58019b43af46810e7e813?source=copy_link) 

# Step 5.1 — Execute the VM setup script from the repository
# This script assumes steps 4.1 to 4.4 have already been done manually:
# - logged in as root
# - updated APT package list / upgraded the base system
# - installed curl and ca-certificates
# - downloaded this setup script into /root

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

run_critical_step()
{
	DESCRIPTION="$1"
	shift

	if ! run_step "$DESCRIPTION" "$@"; then
		printf "${RED}Critical failure. Stopping script.${RESET}\n"
		exit 1
	fi
}

# Step 5.4 — The setup script must run as root
if [ "$(id -u)" -ne 0 ]; then
	printf "${RED}This script must be run as root.${RESET}\n"
	printf "Try:\n"
	printf "  su -\n"
	printf "or:\n"
	printf "  sudo ./setup-vm.sh\n"
	exit 1
fi

section "INSTALLATIONS"

# Step 5.5 — Install the packages managed by the setup script
# Git is installed here because the script was downloaded with curl instead of cloning the repository.
run_critical_step "Updating APT package list" apt update
run_critical_step "Upgrading system packages" apt upgrade -y
run_critical_step "Installing sudo" apt install -y sudo
run_critical_step "Installing git" apt install -y git
run_step "Installing vim" apt install -y vim
run_critical_step "Installing make" apt install -y make
run_critical_step "Installing curl, ca-certificates and gnupg" apt install -y curl ca-certificates gnupg
run_critical_step "Installing graphical support packages" apt install -y xauth x11-apps dbus-x11
run_critical_step "Installing Chromium browser" apt install -y chromium

# Step 5.6 — Create root editor configuration
step "Creating root vim configuration"

if cat > /root/.vimrc << EOF
syntax on
set nu
set rnu
set colorcolumn=81
highlight ColorColumn ctermbg=lightgrey guibg=#eeeeee
EOF
then
	printf "${GREEN}/root/.vimrc created ✅${RESET}\n\n"
	add_success "/root/.vimrc created"
else
	printf "${RED}/root/.vimrc creation failed ❌${RESET}\n\n"
	add_failed "/root/.vimrc creation failed"
fi

section "SSH CHECK"

# Step 5.7 — Check that the SSH service is active and start it if needed
run_critical_step "Installing OpenSSH server" apt install -y openssh-server
run_critical_step "Enabling SSH service" systemctl enable ssh

run_step "Enabling SSH X11 forwarding" sh -c "grep -q '^X11Forwarding yes' /etc/ssh/sshd_config || printf '\nX11Forwarding yes\n' >> /etc/ssh/sshd_config"

if systemctl is-active --quiet ssh; then
	printf "${GREEN}SSH service is already active ✅${RESET}\n\n"
	add_success "SSH service is active"
else
	run_critical_step "Starting SSH service" systemctl start ssh
fi

run_critical_step "Checking SSH service" systemctl is-active --quiet ssh

section "DOCKER INSTALLATION"

# Step 5.8 — Install Docker from the official APT repository
# - Install Docker repository prerequisites
# - Download Docker official GPG key
# - Set Docker GPG key permissions
# - Add Docker official APT repository
# - Update APT after adding Docker repository
# - Install Docker Engine and Docker Compose plugin
run_critical_step "Creating Docker keyrings directory" install -m 0755 -d /etc/apt/keyrings

step "Downloading Docker GPG key"

rm -f /etc/apt/keyrings/docker.gpg

if curl -fsSL https://download.docker.com/linux/debian/gpg \
	| gpg --dearmor -o /etc/apt/keyrings/docker.gpg
then
	printf "${GREEN}Docker GPG key downloaded ✅${RESET}\n\n"
	add_success "Docker GPG key downloaded"
else
	printf "${RED}Docker GPG key download failed ❌${RESET}\n\n"
	add_failed "Docker GPG key download failed"
	exit 1
fi

run_critical_step "Setting Docker GPG key permissions" chmod a+r /etc/apt/keyrings/docker.gpg

step "Adding Docker APT repository"

if echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
	> /etc/apt/sources.list.d/docker.list
then
	printf "${GREEN}Docker APT repository added ✅${RESET}\n\n"
	add_success "Docker APT repository added"
else
	printf "${RED}Docker APT repository failed ❌${RESET}\n\n"
	add_failed "Docker APT repository failed"
	exit 1
fi

run_critical_step "Updating APT after adding Docker repository" apt update

run_critical_step "Installing Docker packages" apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 5.9 — Check and enable Docker
# - Check Docker command
# - Check Docker Compose command
# - Enable Docker service
# - Start Docker service if needed
# - Check Docker service status
# - Check Docker daemon connection
run_critical_step "Checking Docker version" docker --version
run_critical_step "Checking Docker Compose version" docker compose version

section "DOCKER SERVICE CHECK"

run_critical_step "Enabling Docker service" systemctl enable docker

if systemctl is-active --quiet docker; then
	printf "${GREEN}Docker service is already active ✅${RESET}\n\n"
	add_success "Docker service is active"
else
	run_critical_step "Starting Docker service" systemctl start docker
fi

run_critical_step "Checking Docker service" systemctl is-active --quiet docker
run_critical_step "Checking Docker daemon" docker ps

section "CONFIGURATIONS"

# Step 5.10 — Configure the main user groups
step "Configuring main user"

printf "Please, enter the main user: "
read LOGIN

if [ -z "$LOGIN" ]; then
	printf "${RED}Empty user input ❌${RESET}\n\n"
	add_failed "Main user configuration: empty user input"
	exit 1
fi

if ! id "$LOGIN" >/dev/null 2>&1; then
	printf "${RED}User does not exist: %s ❌${RESET}\n\n" "$LOGIN"
	add_failed "Main user does not exist: ${LOGIN}"
	exit 1
fi

if [ ! -d "/home/$LOGIN" ]; then
	printf "${RED}Home directory does not exist: /home/%s ❌${RESET}\n\n" "$LOGIN"
	add_failed "Home directory does not exist: /home/${LOGIN}"
	exit 1
fi

run_critical_step "Adding ${LOGIN} to sudo group" usermod -aG sudo "$LOGIN"
run_critical_step "Adding ${LOGIN} to docker group" usermod -aG docker "$LOGIN"

# Step 5.11 — Create user editor configuration
step "Creating user vim configuration"

if cat > "/home/$LOGIN/.vimrc" << EOF
syntax on
set nu
set rnu
set colorcolumn=81
highlight ColorColumn ctermbg=lightgrey guibg=#eeeeee
EOF
then
	if chown "$LOGIN:$LOGIN" "/home/$LOGIN/.vimrc"; then
		printf "/home/%b%s%b/.vimrc created ✅\n\n" "$YELLOW" "$LOGIN" "$RESET"
		add_success "/home/${LOGIN}/.vimrc created"
	else
		printf "${RED}/home/%s/.vimrc ownership failed ❌${RESET}\n\n" "$LOGIN"
		add_failed "/home/${LOGIN}/.vimrc ownership failed"
	fi
else
	printf "${RED}/home/%s/.vimrc creation failed ❌${RESET}\n\n" "$LOGIN"
	add_failed "/home/${LOGIN}/.vimrc creation failed"
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
