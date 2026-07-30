#!/bin/sh
# Colors
RESET="\033[0m"

BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

BOLD_BLACK="\033[1;30m"
BOLD_RED="\033[1;31m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_BLUE="\033[1;34m"
BOLD_MAGENTA="\033[1;35m"
BOLD_CYAN="\033[1;36m"
BOLD_WHITE="\033[1;37m"

# Instalations
echo "${MAGENTA}/********************/\n"
echo "     INSTALATIONS     \n"
echo "/********************/\n"
echo "${CYAN}==== Updating APT ====${RESET}\n"
apt update
apt upgrade -y
echo "apt updated ✅\n"
echo

echo "${CYAN}==== Installing SUDO ====${RESET}\n"
apt install -y sudo
echo "Sudo installed ✅\n"
echo

echo "${CYAN}==== Installing VIM ====${RESET}\n"
apt install -y vim
cat > /root/.vimrc << EOF
syntax on
set nu
set rnu
EOF
source ~/.vimrc
echo "Vim installed ✅\n"
echo

echo "${CYAN}==== Installing MAKE ====${RESET}\n"
apt install -y make
echo "Make installed ✅\n"
echo

echo "${CYAN}==== Installing CURL ====${RESET}\n"
apt install -y curl
echo "CURL installed ✅\n"
echo

echo "${CYAN}==== Installing DOCKER ====${RESET}\n"
sudo usermod -aG docker $USER
apt install -y ca-certificates gnupg
apt install -m 0755 -d /etc/apt/keyring
curl -fsSL https://download.docker.com/linux/debian/gpg \
| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo "${CYAN}* Installing docker compose *${RESET}\n"
docker compose
docker compose version
echo "DOCKER installed ✅:"
docker --version
echo


# Other configs
echo "${MAGENTA}/********************/\n"
echo "     CONFIGURATIONS     \n"
echo "/********************/\n"
echo "${CYAN}==== Config sudoers ====${RESET}\n"
read -p "Please, enter the main user: " LOGIN
sudo usermod -aG sudo $LOGIN
sudo usermod -aG docker $LOGIN
chown telufulu:telufulu /home/telufulu/.vimrc
echo "${YELLOW}${LOGIN}${RESET} is now sudo ✅"
echo "✅${GREEN} All done! ${RESET}✅"
echo "Try to execute `docker ps`"
