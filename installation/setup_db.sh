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


# Créer le rôle 'aitf_admin' avec mot de passe et droits superuser
echo "Création du rôle '$PG_ROLE'..."
sudo -u $PG_USER psql -c "CREATE ROLE $PG_ROLE WITH SUPERUSER LOGIN PASSWORD '$PG_PASSWORD';"

# Créer la base de données 'ban' et assigner le rôle 'aitf_admin' comme propriétaire
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

# On ajoute les extensions
sudo -u $PG_USER psql -d $PG_DB -c "CREATE EXTENSION postgis;" || true


