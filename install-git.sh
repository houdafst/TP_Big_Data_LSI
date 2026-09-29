#!/usr/bin/env bash

set -Eeuo pipefail

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
echo "          Installation de Git sur Ubuntu"
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

info "Mise à jour des dépôts APT..."

sudo apt-get update

success "Dépôts APT mis à jour."

info "Installation de Git..."

sudo apt-get install -y git

success "Git installé."

echo
echo "=============================================="
echo "              Vérification"
echo "=============================================="
echo

if command -v git >/dev/null 2>&1; then
    success "Git est disponible."
    git --version
else
    die "Git n'a pas pu être installé."
fi

echo
echo "=============================================="
echo -e "${GREEN} Installation terminée avec succès !${NC}"
echo "=============================================="
echo
