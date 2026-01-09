#!/bin/sh
set -e


# Créer un groupe dédié
sudo groupadd aitf

# Ajouter les utilisateurs au groupe
sudo usermod -aG aitf a_user


# création du répertoire du projet
sudo mkdir /srv/aitf
 
# permissions
sudo chown -R :aitf /srv/aitf
sudo chmod -R 775 /srv/aitf


# git clone du projet
cd /srv/aitf/
git clone https://github.com/aitf-sig-topo/tdb_qualite_ban.git

