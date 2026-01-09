# Installation

## Prérequis

* une machine sous linux, de préférence Debian avec :
    * 10 Go d'espace disque
    * 2 CPU
    * 1 Go de RAM
* PostreSQL 13+
* PostGIS 3.1+

Testé sous Debian 12, PostgreSQL 15 et PostGIS 3.3


## Installation du projet

Ouvrir un terminal sur votre machine linux.

Exécuter le script d'installation du projet : `curl -sSL https://raw.githubusercontent.com/aitf-sig-topo/tdb_qualite_ban/refs/heads/main/installation/serveur_configuration.sh | bash`


## Installation des logiciels

Se déplacer dans le répertoire du projet : `cd /srv/aitf/tdb_qualite_ban/installation`.

Exécuter le script d'installation : `./serveur_logiciels.sh`.


## Configuration de la base de données

Exécuter le script de configuration de PostgreSQL : `./setup_postgresql.sh`.

Puis le script de configuration de la base de données : `./setup_db.sh`.

