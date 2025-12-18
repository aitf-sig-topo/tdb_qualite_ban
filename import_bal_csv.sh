#!/bin/sh

BASEDIR=$(cd $(dirname $0) && pwd)

# departement :
SOURCE_URL="https://adresse.data.gouv.fr/data/ban/adresses/latest/csv-bal/adresses-63.csv.gz"
# france entiere : 
# SOURCE_URL="https://adresse.data.gouv.fr/data/ban/adresses/latest/csv-bal/adresses-france.csv.gz"
DB_TABLE=bal_indicateur

OUTPUT_FILE="$BASEDIR/in_bal_csv/bal.csv.gz"


echo "[$(date '+%d/%m/%Y %H:%M:%S')] START IMPORTING $DB_TABLE"

# supprime le fichier existant
rm "$OUTPUT_FILE" 

# ne retelecharge le fichier que s'il n'existe pas déjà
if [ ! -f "$OUTPUT_FILE" ]; then
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD $DB_TABLE"
	wget --no-clobber --progress=bar:force:noscroll -q --show-progress $SOURCE_URL -O "$OUTPUT_FILE"
        gzip -d "$OUTPUT_FILE"
	echo "[$(date '+%d/%m/%Y %H:%M:%S')] DOWNLOAD FINISHED $DB_TABLE"
fi




