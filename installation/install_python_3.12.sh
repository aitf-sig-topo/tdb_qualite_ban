#!/bin/bash

# Script d'installation de Python 3.12.12 sur Debian 12
# Auteur: Script généré pour installation Python
# Date: 2026-01-26

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
PYTHON_VERSION="3.12.12"
PYTHON_MAJOR_MINOR="3.12"
INSTALL_DIR="/usr/local"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Installation de Python ${PYTHON_VERSION}${NC}"
echo -e "${GREEN}=====================================${NC}"

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être exécuté en tant que root (utilisez sudo)${NC}" 
   exit 1
fi

# Mise à jour des paquets
echo -e "${YELLOW}Mise à jour des paquets système...${NC}"
apt update

# Installation des dépendances nécessaires
echo -e "${YELLOW}Installation des dépendances...${NC}"
apt install -y \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libgdbm-dev \
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    libsqlite3-dev \
    libbz2-dev \
    liblzma-dev \
    wget \
    curl \
    llvm \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libgdbm-compat-dev

# Création du répertoire temporaire
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Téléchargement de Python
echo -e "${YELLOW}Téléchargement de Python ${PYTHON_VERSION}...${NC}"
wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

# Extraction de l'archive
echo -e "${YELLOW}Extraction de l'archive...${NC}"
tar -xzf "Python-${PYTHON_VERSION}.tgz"
cd "Python-${PYTHON_VERSION}"

# Configuration de la compilation
echo -e "${YELLOW}Configuration de Python...${NC}"
./configure \
    --prefix="${INSTALL_DIR}" \
    --enable-optimizations \
    --enable-shared \
    --with-system-ffi \
    --with-computed-gotos \
    --enable-loadable-sqlite-extensions \
    LDFLAGS="-Wl,-rpath ${INSTALL_DIR}/lib"

# Compilation (utilise tous les coeurs disponibles)
echo -e "${YELLOW}Compilation de Python (cela peut prendre plusieurs minutes)...${NC}"
make -j$(nproc)

# Installation
echo -e "${YELLOW}Installation de Python...${NC}"
make altinstall

# Configuration de ldconfig pour les bibliothèques partagées
echo "${INSTALL_DIR}/lib" > /etc/ld.so.conf.d/python${PYTHON_MAJOR_MINOR}.conf
ldconfig

# Nettoyage
echo -e "${YELLOW}Nettoyage des fichiers temporaires...${NC}"
cd /
rm -rf "$TEMP_DIR"

# Mise à jour de pip
echo -e "${YELLOW}Mise à jour de pip...${NC}"
"${INSTALL_DIR}/bin/python${PYTHON_MAJOR_MINOR}" -m pip install --upgrade pip

# Création de liens symboliques optionnels (commentés par défaut)
# Décommentez ces lignes si vous souhaitez que python3.12 soit accessible via 'python3'
# echo -e "${YELLOW}Création de liens symboliques...${NC}"
# update-alternatives --install /usr/bin/python3 python3 ${INSTALL_DIR}/bin/python${PYTHON_MAJOR_MINOR} 1
# update-alternatives --install /usr/bin/pip3 pip3 ${INSTALL_DIR}/bin/pip${PYTHON_MAJOR_MINOR} 1

# Vérification de l'installation
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Installation terminée !${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${GREEN}Version installée :${NC}"
"${INSTALL_DIR}/bin/python${PYTHON_MAJOR_MINOR}" --version
echo ""
echo -e "${GREEN}Emplacement :${NC}"
which "${INSTALL_DIR}/bin/python${PYTHON_MAJOR_MINOR}" || echo "${INSTALL_DIR}/bin/python${PYTHON_MAJOR_MINOR}"
echo ""
echo -e "${GREEN}Version de pip :${NC}"
"${INSTALL_DIR}/bin/pip${PYTHON_MAJOR_MINOR}" --version
echo ""
echo -e "${YELLOW}Pour utiliser Python ${PYTHON_VERSION}, utilisez :${NC}"
echo -e "  python${PYTHON_MAJOR_MINOR}"
echo -e "  ou le chemin complet : ${INSTALL_DIR}/bin/python${PYTHON_MAJOR_MINOR}"
echo ""
echo -e "${YELLOW}Note : Python 3.11.2 reste disponible via /usr/bin/python3.11${NC}"