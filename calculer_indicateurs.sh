#!/bin/sh
set -e

echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Calcul des indicateurs de qualité"
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
echo "Suppression des données pré-existantes"
echo ""

# on vide la table sur le périmètre de travail
if [ "$BAL_TO_TREAT" = "france" ]; then
    # on va vider toute la table
    SQL_DELETE="TRUNCATE TABLE bal_indicateurs ;"
else
    # on ne supprime que les données du département
    SQL_DELETE="DELETE FROM bal_indicateurs WHERE LEFT(commune_insee, 2) = '$BAL_TO_TREAT';"
fi

PSQL_CMD="$PSQL_BASE_CMD -c \"$SQL_DELETE\""
# echo "$PSQL_CMD"
eval "$PSQL_CMD"
echo "fait"



echo ""
echo "Calcul des indicateurs"
echo ""
# echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""

if [ "$BAL_TO_TREAT" = "france" ]; then
    SQL_WHERE_CLAUSE=""
else
    SQL_WHERE_CLAUSE="AND LEFT(commune_insee, 2) = '$BAL_TO_TREAT'"
fi

# On charge le fichier SQL dans une variable
SQL_MAJ=$(cat sql/maj_indicateurs.sql)

# Remplacement de la clause WHERE
SQL_COMPUTE=$(echo "$SQL_MAJ" | sed "s/#where_clause#/$SQL_WHERE_CLAUSE/g")

# exécution
PSQL_CMD="$PSQL_BASE_CMD -c \"$SQL_COMPUTE\""
# echo "$PSQL_CMD"
eval "$PSQL_CMD"
echo "fait"


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  FINI"
echo ""
echo "[$(date '+%d/%m/%Y %H:%M:%S')]"
echo ""
echo ""
