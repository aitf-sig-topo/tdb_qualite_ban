#!/bin/bash


# Variables
PG_USER="postgres"
PG_ROLE="aitf_admin"
PG_PASSWORD="vivelaterritoriale"
PG_DB="ban"
PG_HBA_CONF="/etc/postgresql/*/main/pg_hba.conf"
PG_CONF="/etc/postgresql/*/main/postgresql.conf"
PG_SERVICE="postgresql"
PG_PASS_FILE="$HOME/.pgpass"


# 1. Créer le rôle 'aitf_admin' avec mot de passe et droits superuser
echo "Création du rôle '$PG_ROLE'..."
sudo -u $PG_USER psql -c "CREATE ROLE $PG_ROLE WITH SUPERUSER LOGIN PASSWORD '$PG_PASSWORD';"

# 2.1 Créer la base de données 'ban' et assigner le rôle 'aitf_admin' comme propriétaire
echo "Création de la base de données '$PG_DB'..."

# on tue les connexions en cours
sudo -u $PG_USER psql -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'ban'
AND leader_pid IS NULL;"

# on supprime
sudo -u $PG_USER psql -c "DROP DATABASE $PG_DB ;"

# on recrée
sudo -u $PG_USER psql -c "CREATE DATABASE $PG_DB OWNER $PG_ROLE;"


# 2.2 Les extensions
sudo -u $PG_USER psql -d $PG_DB -c "CREATE EXTENSION postgis;" || true


# 3. Modifier le fichier pg_hba.conf pour autoriser l'accès depuis n'importe où
echo "Modification de $PG_HBA_CONF pour autoriser l'accès..."
echo "host    all             aitf_admin      0.0.0.0/0               scram-sha-256" | sudo tee -a $PG_HBA_CONF

# 4. Modifier le fichier postgresql.conf pour écouter sur toutes les adresses
echo "Modification de $PG_CONF pour écouter sur toutes les adresses..."
sudo sed -i "s/^#listen_addresses = '.*'/listen_addresses = '*'/" $PG_CONF

# 5. Redémarrer le service PostgreSQL
echo "Redémarrage du service $PG_SERVICE..."
sudo systemctl restart $PG_SERVICE

# 6. Pare-feu
sudo ufw allow 5432/tcp
sudo ufw reload

# 7. Fichier pgpass
echo "Création du fichier $PG_PASS_FILE..."
touch "$PG_PASS_FILE"
chmod 600 "$PG_PASS_FILE"
echo "localhost:5432:$PG_DB:$PG_ROLE:$PG_PASSWORD" >> "$PG_PASS_FILE"

echo "Script terminé avec succès !"
