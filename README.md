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
- ogr2ogr installé (pour l'import des contours de communes)

## Carte synthétique
On peut agréger les indicateurs en un seul, selon une pondération à affiner.

## Carte des indicateurs détaillés
On peut également affiner la symbologie pour avoir une représentation par indicateur.

Par exemple : 

- Ellipse vert clair : sa largeur représente la longévité de la BAL, sa hauteur le nombre de date distinctes de mise à jour. Une ellipse plate indique une BAL ancienne mais mise à jour à intervalles peu régulier, une ellipse en hauteur indique une BAL fréquemment mise à jour et relativement récente. 
Indicateur secondaire : plus la couleur de l'ellipse est transparente, moins il y a d'adresses certifiées.

- Losange vert foncé : plus il est gros, plus il y a eu d'adresses mises à jour au cours des deux dernières années. 
Indicateur secondaire : lorsque seul le contour du losange est représenté, cela signifie que toutes les adresses de la BAL ont été mises à jour ces deux dernières années (ce qui indique une mise à jour en masse de la BAL, pas forcément gage de qualité).

- Point d'exclamation noir : indique la présence d'adresses 	superposées, signe que la BAL n'est pas encore nettoyée.
Croix noire : représentative du taux d’adresses de source non communales.





