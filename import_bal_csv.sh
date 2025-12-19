#!/bin/sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)
# departement :
SOURCE_URL="https://adresse.data.gouv.fr/data/ban/adresses/latest/csv-bal/adresses-63.csv.gz"
# france entiere : 
# SOURCE_URL="https://adresse.data.gouv.fr/data/ban/adresses/latest/csv-bal/adresses-france.csv.gz"
DB_TABLE=bal_brute
OUTPUT_FILE="$BASEDIR/in_bal_csv/bal.csv"
# acces base de données postgresql (a décommenter et renseigner)
POSTGRES_PORT=5432
# POSTGRES_HOST=mon_serveur_postgres
# POSTGRES_DB=ma_base_de_donnee
# POSTGRES_USERNAME=monutilisateur
# export PGPASSWORD="monmotdepasse"

export PSQL_CMD="psql -U $POSTGRES_USERNAME -h $POSTGRES_HOST -p $POSTGRES_PORT -d $POSTGRES_DB"


echo "[$(date '+%d/%m/%Y %H:%M:%S')] START IMPORTING $DB_TABLE"

# supprime le fichier existant (à commmenter si on souhaite conserver le fichier existant)
# rm "$OUTPUT_FILE" 

# ne retelecharge le fichier que s'il n'existe pas déjà, et le dezippe
if [ ! -f "$OUTPUT_FILE" ]; then
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD $DB_TABLE"
	wget --no-clobber --progress=bar:force:noscroll -q --show-progress $SOURCE_URL -O "$OUTPUT_FILE".gz
        gzip -d "$OUTPUT_FILE".gz
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD FINISHED $DB_TABLE"
fi

# cree la table si elle n'existe pas dejà
eval "$PSQL_CMD -f ./sql/create_table_bal.sql"

# importe le fichier en base postgresql
# echo "$PSQL_CMD -c '\copy $DB_TABLE FROM $OUTPUT_FILE WITH (delimiter \";\", format csv, header true)'"
eval "$PSQL_CMD -c '\copy $DB_TABLE FROM $OUTPUT_FILE WITH (delimiter \";\", format csv, header true)'"
echo "[$(date '+%d/%m/%Y %H:%M:%S')] END IMPORTING $DB_TABLE"



