# Crée la table des indicateurs bal en requêtant dans la table bal_brute et joignant avec la table des contours des communes.

# lecture du fichier de configuration
. config.sh

echo "[$(date '+%d/%m/%Y %H:%M:%S')] DEBUT Création table indicateurs BAL"

# script SQL de creation des indicateur
eval "$PSQL_CMD -f ./sql/create_table_bal_indicateurs.sql"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] FIN Création table indicateurs BAL"
