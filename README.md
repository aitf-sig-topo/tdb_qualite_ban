# tdb_qualite_ban
Tableau de bord d'analyse de qualité de la Base Adresse Nationale

## Décrire la vitalité des BAL
On se propose de décrire l'activité d'une BAL à l'aide de plusieurs indicateurs complémentaires.

Proposition d'indicateurs 
- Longévité de la BAL : durée entre la 1ère date de mise à jour et la dernière date. Donne un aperçu de l'ancienneté de la BAL
- Nombre de dates distinctes de mises à jour : permet d'estimer la régularité de la mise à jour au fil du temps.
- Nombre d'adresses mises à jour depuis 2 ans : pour quantifier les mises à jour récentes de la BAL, donne un aperçu de l'activité actuelle de la BAL.
- Taux de certification des adresses.
- Taux d’adresses de source communale.
- Nombre d'adresses superposées les unes aux autres : "géodoublons", 	caractéristiques d'une BAL qui n'a pas été "nettoyée" des anciennes adresses du cadastre.

## Création des indicateurs
Import des BAL au choix sur la france entière, ou par département.

On importe le fichier csv via un script SQL dans une base PostgreSql, et on produit également les indicateurs via SQL.

Prérequis pour les scripts : 
- une base postgresql avec extension postgis
- plsql installé (pour import sql des tables bal et creation de la table des indicateurs)
    
    sudo apt-get install postgreSql
    
- ogr2ogr installé (pour l'import du geojson des contours de communes)
    
    sudo apt-get install gdal-bin
    
### Donner les droit d'exécution au scripts
Les scripts sh n'ont pas pas défaut les droits en exécution, leur donner :

    chmod +x *.sh

### Script d'import des fichiers bal 
Editer le fichier import_bal_csv.sh et modifier les paramètres en début de script. 
- SOURCE_URL : spécifier le département souhaité, ou choisir le fichier france entière
- paramètre POSTGRES_ : renseigner les paramètres de connexion à la base (décommenter les lignes)

Lancer le script : 

    ./import_bal_csv.sh
    
Si on souhaite importer les tables dans un schéma postgres particulier, il faut changer le schéma par défaut de l'utilisateur qui importe les données. En effet, dans les scripts sql qui sont appelés par la suite, la table sera mentionnée sans son schéma.

Attention, pour le fichier france entière, l'import dure un petit quart d'heure.
    
### Script d'import des contours de communes
Les contour de communes sont nécessaires pour cartographier les indicateurs. On récupère les contours simplifié des communes pour alléger les données (voir l'url de téléchargement des données dans le script).
Renseigner les paramètres base de donnée dans le script et le lancer : 

    ./import_contour_commune.sh
    
Attention, pour le moment, les contours des communes avec arrondissements n'est pas récupéré dans le fichier insee.
    
### Script de creation de la table des indicateurs
Une fois le fichier bal importé et les contours des communes importés également, il est possible de générer la table des indicateurs qualité par commune. Renseigner les paramètres base de donnée dans le script et le lancer : 

    ./cree_table_bal_indicateurs.sh
    
Pour la france entière, le traitement dure une dizaine de minutes.

### Script d'export de la table des indicateurs en geojson
Une fois la table des indicateurs créée dans Postgresql, on peut l'exporter en geojson. Cela permet par exemple de l'intégrer dans UMap.

Renseigner les paramètres base de donnée dans le script et le lancer : 

    ./export_indicateurs_en_geojson.sh
    
Le fichier résultat se trouve dans le dossier "out".

## Carte synthétique
On peut agréger les indicateurs en un seul, selon une pondération à affiner.
L'indicateur aggrégé est calculé à la fin du script create_table_bal_indicateurs.sql.







