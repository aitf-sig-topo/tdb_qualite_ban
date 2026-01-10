#!/bin/bash

# lecture du fichier de configuration
source "../config.sh"

# Créer le rôle 'aitf_admin' avec mot de passe et droits superuser
echo "Création du rôle '$PG_USERNAME'..."
sudo -u postgres psql -c "CREATE ROLE $PG_USERNAME WITH SUPERUSER LOGIN PASSWORD '$PG_PASSWORD';"

# Créer la base de données 'ban' et assigner le rôle 'aitf_admin' comme propriétaire
echo "Création de la base de données '$PG_DB'..."

# on tue les connexions en cours
sudo -u postgres psql -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$PG_DB'
AND leader_pid IS NULL;"

# on supprime
sudo -u postgres psql -c "DROP DATABASE $PG_DB ;"

# on recrée
sudo -u postgres psql -c "CREATE DATABASE $PG_DB OWNER $PG_USERNAME;"

# On ajoute les extensions
sudo -u postgres psql -d $PG_DB -c "CREATE EXTENSION postgis;" || true

# On crée un schéma dédié
sudo -u postgres psql -d $PG_DB -c "CREATE SCHEMA ban_qualite AUTHORIZATION $PG_USERNAME;" || true

# on modifie le search_path par défaut
sudo -u postgres psql -d $PG_DB -c "ALTER DATABASE $PG_DB SET search_path TO ban_qualite, public;" || true

