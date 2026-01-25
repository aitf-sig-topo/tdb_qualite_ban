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

# variable indiquant qu'on ne telecharge pas le fichier si un autre suffisamment récent est déjà présent (la variable indique la durée de rétention du fichier en secondes)
MAX_AGE_SECONDS=$((24 * 3600))

# Initialisation de la variable BAL_TO_TREAT : par défaut "france", si on souhaite un département particulier, rajouter la variable -dpt XX au lancement du script
BAL_TO_TREAT="france"

# date de récupération souhaité, voir https://adresse.data.gouv.fr/data/ban/adresses pour la liste des date disponibles
BAL_DATE="latest"


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
        -date)
            if [ -n "$2" ]; then
                BAL_DATE="$2"
                shift 2
            else
                echo "Erreur : L'argument pour -date est manquant."
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

BAL_URL="https://adresse.data.gouv.fr/data/ban/adresses/$BAL_DATE/csv-bal/adresses-$BAL_TO_TREAT.csv.gz"
BAL_FILE="in/bal_csv/$BAL_TO_TREAT.csv"

# on va télécharger que si un fichier BAL récent n'existe pas déjà dans le répertoire

if [ ! -f "$BAL_FILE" ]; then
    
    echo "Téléchargement du fichier BAL $BAL_DATE" 

    echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
    wget --no-clobber --progress=bar:force:noscroll -q --show-progress $BAL_URL -O "$BAL_FILE.gz"
    gzip -d -f "$BAL_FILE.gz"
    echo "[$(date '+%d/%m/%Y %H:%M:%S')]"

else
    
    echo "un fichier récent existe déjà"
    
    # On vérifie l'âge du fichier
    FILE_AGE_SECONDS=$(( $(date +%s) - $(stat -c %Y "$BAL_FILE") ))

    if [ "$FILE_AGE_SECONDS" -ge "$MAX_AGE_SECONDS" ]; then
        echo "Le fichier existant est trop ancien. Téléchargement du fichier BAL"
        echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
        wget --no-clobber --progress=bar:force:noscroll -q --show-progress $BAL_URL -O "$BAL_FILE.gz"
        gzip -d -f "$BAL_FILE.gz"
        echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
    else
        echo "Le fichier a été téléchargé récemment. Aucun téléchargement nécessaire."
        
        # et on s'arrête là
        exit 0
        echo ""
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        echo "  FINI"
    fi



    
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
echo "fait"


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
echo "$PSQL_CMD"
eval "$PSQL_CMD"
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo "fait"


if [ "$BAL_TO_TREAT" = "france" ]; then
    # on recrée les indexes
    echo "Création des indexes"
    PSQL_CMD="$PSQL_BASE_CMD -f ./sql/create_indexes_bal_brute.sql"
    # echo "$PSQL_CMD"
    eval "$PSQL_CMD"
    echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
    echo "fait"
fi

echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
