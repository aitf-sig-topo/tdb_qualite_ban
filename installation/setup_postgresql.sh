#!/bin/bash

# lecture du fichier de configuration
source "../config.sh"

PG_HBA_CONF="/etc/postgresql/*/main/pg_hba.conf"
PG_CONF="/etc/postgresql/*/main/postgresql.conf"
PG_SERVICE="postgresql"
PG_PASS_FILE="$HOME/.pgpass"


# Modifier le fichier pg_hba.conf pour autoriser l'accès depuis n'importe où
echo "Modification de $PG_HBA_CONF pour autoriser l'accès..."
echo "host    all             aitf_admin      0.0.0.0/0               scram-sha-256" | sudo tee -a $PG_HBA_CONF

# Modifier le fichier postgresql.conf pour écouter sur toutes les adresses
echo "Modification de $PG_CONF pour écouter sur toutes les adresses..."
sudo sed -i "s/^#listen_addresses = '.*'/listen_addresses = '*'/" $PG_CONF

# 5. Redémarrer le service PostgreSQL
echo "Redémarrage du service $PG_SERVICE..."
sudo systemctl restart $PG_SERVICE

# 6. Pare-feu
sudo ufw allow 5432/tcp
sudo ufw reload

# Fichier pgpass
echo "Création du fichier $PG_PASS_FILE..."
touch "$PG_PASS_FILE"
chmod 600 "$PG_PASS_FILE"
echo "localhost:5432:$PG_DB:$PG_USERNAME:$PG_PASSWORD" >> "$PG_PASS_FILE"

echo "Script terminé avec succès !"
