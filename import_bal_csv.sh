#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Import d'un fichier BAL"
echo ""

# lecture du fichier de configuration
. ./config.sh

# repertoire de travail
BASEDIR=$(cd $(dirname $0) && pwd)


# Initialisation de la variable BAL_TO_TREAT
BAL_TO_TREAT="france"

# Vérification des arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -dpt)
            if [ -n "$2" ]; then
                BAL_TO_TREAT="$2"
                shift 2
            else
                echo "Erreur : L'argument pour -dpt est manquant."
                exit 1
            fi
            ;;
        *)
            echo "Option inconnue : $1"
            exit 1
            ;;
    esac
done

if [ "$BAL_TO_TREAT" = "france" ]; then
    echo "On va travailler sur la France entière"
else
    echo "On va travailler sur le département $BAL_TO_TREAT"
fi


echo ""

BAL_URL="https://adresse.data.gouv.fr/data/ban/adresses/latest/csv-bal/adresses-$BAL_TO_TREAT.csv.gz"
BAL_FILE="in_bal_csv/$BAL_TO_TREAT.csv"

# on va télécharger que si un fichier BAL récent n'existe pas déjà dans le répertoire

if [ ! -f "$BAL_FILE" ]; then
    
    echo "Téléchargement du fichier BAL"

    echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
    wget --no-clobber --progress=bar:force:noscroll -q --show-progress $BAL_URL -O "$BAL_FILE.gz"
    gzip -d -f "$BAL_FILE.gz"
    echo "[$(date '+%d/%m/%Y %H:%M:%S')]"

else
    
    echo "un fichier récent existe déjà : on ne le réimporte pas"
    echo ""
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "  FINI"

    # et on s'arrête là
    exit 0
fi

echo ""
echo "Suppression des données pré-existantes"
echo ""

if [ "$BAL_TO_TREAT" = "france" ]; then
    # on va vider toute la table
    SQL_DELETE="TRUNCATE TABLE bal_brute;"
else
    # on ne supprime que les données du département
    SQL_DELETE="DELETE FROM bal_brute WHERE LEFT(commune_insee, 2) = '$BAL_TO_TREAT';"
fi

PSQL_CMD="$PSQL_BASE_CMD -c \"$SQL_DELETE\""
# echo "$PSQL_CMD"
eval "$PSQL_CMD"


if [ "$BAL_TO_TREAT" = "france" ]; then
    # on va supprimer les indexes pour un chargement plus rapide
    echo "Suppression des indexes"
    echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
    PSQL_CMD="$PSQL_BASE_CMD -f ./sql/drop_indexes_bal_brute.sql"
    # echo "$PSQL_CMD"
    eval "$PSQL_CMD"
    echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
    echo "fait"
fi


echo ""
echo "Import du fichier BAL dans la base de données"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"

PSQL_CMD="$PSQL_BASE_CMD -c \"\\\\COPY bal_brute FROM '$BAL_FILE' WITH (delimiter ';', format csv, header true)\""
#echo "$PSQL_CMD"
eval "$PSQL_CMD"



if [ "$BAL_TO_TREAT" = "france" ]; then
    # on recrée les indexes
    echo "Création des indexes"
    PSQL_CMD="$PSQL_BASE_CMD -f ./sql/create_indexes_bal_brute.sql"
    # echo "$PSQL_CMD"
    eval "$PSQL_CMD"
    echo "fait"
fi

echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
