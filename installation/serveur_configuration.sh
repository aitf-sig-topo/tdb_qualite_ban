#!/bin/sh


# Récupérer l'utilisateur courant
CURRENT_USER=$(whoami)

# Créer un groupe dédié
echo "Création du groupe aitf..."
sudo groupadd aitf 2>/dev/null || echo "Le groupe 'aitf' existe déjà."

# Ajouter l'utilisateur courant au groupe aitf
echo "Ajout de $CURRENT_USER au groupe aitf..."
sudo usermod -aG aitf "$CURRENT_USER"

# pour prise en compte immédiate
newgrp aitf
# la commande inverse : gpasswd -d $CURRENT_USER aitf


# création du répertoire du projet
sudo mkdir /srv/aitf
 
# permissions
sudo chown -R nobody:aitf /srv/aitf/
sudo chmod -R 775 /srv/aitf/

# Appliquer setgid pour que les nouveaux fichiers appartiennent au groupe aitf
sudo chmod g+s /srv/aitf


echo "clone du projet..."

# git clone du projet
cd /srv/aitf/
git clone https://github.com/aitf-sig-topo/tdb_qualite_ban.git

echo "fait"

