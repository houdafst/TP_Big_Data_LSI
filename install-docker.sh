#!/usr/bin/env bash

set -Eeuo pipefail

DOCKER_REPO="https://download.docker.com/linux/ubuntu"
DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"
DOCKER_SOURCE="/etc/apt/sources.list.d/docker.sources"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

die() {
    error "$*"
    exit 1
}

trap 'error "Erreur à la ligne $LINENO"' ERR

echo
echo "=============================================="
echo "       Installation automatique de Docker"
echo "=============================================="
echo

info "Vérification du système..."

if [ ! -f /etc/os-release ]; then
    die "Impossible de déterminer le système."
fi

source /etc/os-release

if [ "${ID:-}" != "ubuntu" ]; then
    die "Ce script nécessite Ubuntu."
fi

UBUNTU_VERSION="${VERSION_ID:-}"
UBUNTU_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
ARCHITECTURE="$(dpkg --print-architecture)"

success "Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"
success "Architecture : ${ARCHITECTURE}"

info "Vérification de sudo..."

if [ "$EUID" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "sudo n'est pas installé."
    sudo -v
fi

success "Privilèges administrateur OK."

info "Installation des prérequis..."

sudo apt-get update
sudo apt-get install -y ca-certificates curl

success "Prérequis installés."

info "Configuration de la clé GPG Docker..."

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl \
    -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o "$DOCKER_KEYRING"

sudo chmod a+r "$DOCKER_KEYRING"

success "Clé GPG installée."

info "Configuration du dépôt Docker..."

sudo tee "$DOCKER_SOURCE" > /dev/null <<EOF
Types: deb
URIs: ${DOCKER_REPO}
Suites: ${UBUNTU_CODENAME}
Components: stable
Architectures: ${ARCHITECTURE}
Signed-By: ${DOCKER_KEYRING}
EOF

success "Dépôt Docker configuré."

info "Mise à jour des dépôts..."

sudo apt-get update

info "Installation de Docker..."

sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

success "Docker installé."

info "Activation et démarrage de Docker..."

sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl start docker.service

if sudo systemctl is-active --quiet docker.service; then
    success "Docker est actif."
else
    sudo systemctl status docker.service --no-pager
    die "Docker n'a pas pu démarrer."
fi

echo
echo "=============================================="
echo "              Vérification"
echo "=============================================="
echo

sudo docker --version
sudo docker compose version

echo
info "Test de Docker avec hello-world..."

sudo docker run --rm hello-world

echo
echo "=============================================="
echo -e "${GREEN} Installation terminée avec succès !${NC}"
echo "=============================================="
echo


