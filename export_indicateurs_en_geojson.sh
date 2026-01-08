# Exporte la table des indicateurs par commune en geojson, pour pouvoir l'afficher dans UMap

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)

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

ogr2ogr -f "GeoJSON" "$BASEDIR/out/bal_indicateurs.geojson" -t_srs EPSG:4326 PG:"host=$POSTGRES_HOST port=$POSTGRES_PORT dbname=$POSTGRES_DB user=$POSTGRES_USERNAME password=$PGPASSWORD" bal_indicateurs 


