#!/bin/sh


# Créer un groupe dédié
echo "Création du groupe aitf"
sudo groupadd aitf

# Demande à l'utilisateur de saisir une liste de comptes séparés par des espaces
read -p "Entrez la liste des utilisateurs à ajouter au groupe 'aitf' (séparés par des espaces) : " users

# Boucle sur chaque utilisateur
for user in $users; do
    echo "Ajout de $user au groupe aitf..."
    sudo usermod -aG aitf "$user"
    echo "Fait pour $user."
done


# création du répertoire du projet
sudo mkdir /srv/aitf
 
# permissions
sudo chown -R :aitf /srv/aitf
sudo chmod -R 775 /srv/aitf

echo "clone du projet..."

# git clone du projet
cd /srv/aitf/
git clone https://github.com/aitf-sig-topo/tdb_qualite_ban.git

echo "fait"

