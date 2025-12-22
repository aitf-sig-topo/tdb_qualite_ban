# Crée la table des indicateurs bal en requêtant dans la table bal_brute et joignant avec la table des contours des communes.

# besoin de connexion postgresql
# definit paramètre base de donnée si ce n'est déjà fait
if [ -z "${POSTGRES_HOST}" ]; then
    # Paramètres de connexion à la base de données
    export POSTGRES_PORT=5432
    export POSTGRES_HOST=mon_serveur_postgres
    export POSTGRES_DB=ma_base_de_donnee
    export POSTGRES_USERNAME=monutilisateur
    export PGPASSWORD="monmotdepasse"
fi
PSQL_CMD="psql -U $POSTGRES_USERNAME -h $POSTGRES_HOST -p $POSTGRES_PORT -d $POSTGRES_DB"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] DEBUT Création table indicateurs BAL"

# script SQL de creation des indicateur
eval "$PSQL_CMD -f ./sql/create_table_bal_indicateurs.sql"

echo "[$(date '+%d/%m/%Y %H:%M:%S')] FIN Création table indicateurs BAL"
