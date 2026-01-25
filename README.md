# Tableau de bord d'analyse de qualité de la Base Adresse Nationale



## Objectif : décrire la vitalité des données adresses, à l'échelle communale

On se propose de décrire l'activité d'une BAL à l'aide de plusieurs indicateurs complémentaires.

### Indicateurs retenus : 

- Longévité de la BAL : durée entre la 1ère date de mise à jour et la dernière date. Donne un aperçu de l'ancienneté de la BAL
- Nombre de dates distinctes de mises à jour : permet d'estimer la régularité de la mise à jour au fil du temps.
- Nombre d'adresses mises à jour depuis 2 ans : pour quantifier les mises à jour récentes de la BAL, donne un aperçu de l'activité actuelle de la BAL.
- Taux de certification des adresses.
- Taux d’adresses de source communale.
- Nombre d'adresses superposées les unes aux autres : "géodoublons", caractéristiques d'une BAL qui n'a pas été "nettoyée" des anciennes adresses du cadastre.


## Installation

Voir le [README](installation/README.md) dans le répertoire `installation`.


## Utilisation

### Création des tables

Exécuter le script d'import :
 
    ./creer_tables.sh



### Configuration du référentiel communal

Les limites des communes sont nécessaires pour cartographier les indicateurs. On a également besoin du classement par densité des communes pour affiner l'indicateur aggrégé.

- IGN pour le contour des communes : [https://geoservices.ign.fr/telechargement-api/ADMIN-EXPRESS-COG-CARTO-PE?zone=FXX&format=GPKG](https://geoservices.ign.fr/telechargement-api/ADMIN-EXPRESS-COG-CARTO-PE?zone=FXX&format=GPKG)

- INSEE pour le classement par densité des communes : [https://www.insee.fr/fr/information/8571524](https://geoservices.ign.fr/telechargement-api/ADMIN-EXPRESS-COG-CARTO-PE?zone=FXX&format=GPKG)

Exécuter le script d'import :
 
    ./import_referentiel_communal.sh

/!\ Attention, pour le moment, les limites des communes avec arrondissements n'est pas récupéré dans le fichier insee.

    

### Import des fichiers BAL

Lancer le script pour importer la France entière :

    ./import_bal_csv.sh

Ou sur un seul département :

    ./import_bal_csv.sh -dpt 29
    
Pour importer une date précise (voir liste des date ici : [https://adresse.data.gouv.fr/data/ban/adresses](https://geoservices.ign.fr/telechargement-api/ADMIN-EXPRESS-COG-CARTO-PE?zone=FXX&format=GPKG)) 

    ./import_bal_csv.sh -date 2023-01-04

Attention, pour le fichier BAL France entière, l'import dure un petit quart d'heure.


### Création des indicateurs

Une fois les 2 étapes précédentes réalisées, on peut générer la table des indicateurs qualité par commune : 

    ./calculer_indicateurs.sh

Pour la france entière, le traitement dure une dizaine de minutes.

Ou pour mettre un jour un seul département :

    ./calculer_indicateurs.sh -dpt 29


### Export de la table des indicateurs en geojson

Une fois la table des indicateurs créée dans Postgresql, on peut l'exporter en geojson. Cela permet par exemple de l'intégrer dans UMap : 

    ./export_indicateurs_en_geojson.sh
    
Le fichier résultat se trouve dans le dossier "out".


## Exploitation

### Carte synthétique

On peut agréger les indicateurs en un seul, selon une pondération à affiner.

L'indicateur aggrégé est calculé à la fin du script `create_table_bal_indicateurs.sql`.
Il synthétise l'ensemble des indicateurs vu précédemment.

Chaque indicateur est ramené à une note entre 0 et 10 puis est pondéré selon l'importance qu'on souhaite lui attribuer. La pondération est empirique et se base sur l'observation de communes connues.

Par exemple, pour l'indicateur "nombre de date distinctes de mises à jour", on a le code SQL qui est le suivant : 

            case when classement in ('Rural à habitat dispersé', 'Rural à habitat très dispersé' ) then 
              ( greatest( coalesce(log( 5, "nb_dates_distinctes" + 0.0001 ),0),0) * 6 )   * 2.0
            else 
              ( greatest( coalesce(log( 5, "nb_dates_distinctes" + 0.0001 ),0),0) * 6 )   * 1.0
            end

On l'explique ainsi : 

- on applique une fonction logarithmique à l'indicateur, pour masquer l'effet d'échelle. On prend ici une base 5 pour le logarithme, car on considère que 5 dates distinctes de mise à jour est déjà significatif d'une commune qui a oeuvré pour sa BAL avec plus d'attention qu'une commune qui n'en a aucune 
- L'ajout de 0.0001 sert juste à éviter de calculer un logarithme de zéro, qui renverrai une erreur
- Le "greatest" sert à donner la valeur 0 plutôt qu'une valeur négative, pour ne pas déséquilibrer la pondération.
- le coefficien 6 sert à ramener cet indicateur entre approximativement 0 et 10.
- On distingue les communes selon leur classement de densité pour appliquer un coefficient plus fort à l'habitat rural dispersé. En effet la valeur moyenne de cet indicateur dans ce type de commune est statistiquement plus faible du fait d'une plus grande stabilité des adresses. Pour ne pas pénaliser ce type de commmune, on multiplie donc par 2 cet indicateur.

Les autres indicateurs sont construits de la même façon dans le code SQL, et l'indicateur aggrégé est donc la somme du total.

En complément, voici le code SQL pour connaitre les moyennes et écart-type de cet indicateur par classement de commune.
Cette requête permet d'affiner la pondération.

    select classement, 
            round( max(  ( greatest( coalesce(log( 5, "nb_dates_distinctes" + 0.00001 ),0),0) * 6 )  ) )
                as max_nb_jours_maj,
            round( avg(  ( greatest( coalesce(log( 5, "nb_dates_distinctes" + 0.00001 ),0),0) * 6 ) ) )
                as moy_nb_jours_maj,
            round( stddev(  ( greatest( coalesce(log( 5, "nb_dates_distinctes" + 0.00001 ),0),0) * 6 )  ) )
                as ecart_nb_jours_maj
    from bal_indicateurs group by classement ;
    
Qui renvoie par exemple : 
    
               classement           | max_nb_jours_maj | moy_nb_jours_maj | ecart_nb_jours_maj
    --------------------------------+------------------+------------------+--------------------
     Bourgs ruraux                  |               23 |                8 |                  6
     Ceintures urbaines             |               23 |                8 |                  6
     Centres urbains intermédiaires |               25 |               10 |                  7
     Grands centres urbains         |               28 |                9 |                  7
     Petites villes                 |               26 |                9 |                  6
     Rural à habitat dispersé       |               21 |                4 |                  4
     Rural à habitat très dispersé  |               20 |                3 |                  4    
     

## Historisation

Lancer ce script pour créer un point d'historisation des indicateurs (à lancer par cron 1x par mois) :

    ./creer_historique.sh



## Modèle de données

![](images/db_diagram.png)


