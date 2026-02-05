
-- calcul des indicateurs a partir de la table bal_brute et copie du résultat dans une table bal_indicateurs
WITH
bal as ( 
    -- csv bal importé dans postgresql 
    SELECT 
        * 
    FROM 
        bal_brute
    WHERE 
        -- elimine cas très particulier de cette commune en doublon au 05-02-2026, il faudrait faire un code plus générique mais en attendant...
        not (commune_nom = 'Beaumesnil' and commune_insee = '27049') 
        -- where contextuel injecté par commande sh
        #where_clause#
),
-- indicateurs simples sur les communes (serviront aux autres indicateurs)
indicateurs_de_base_par_commune as (
    SELECT 
        commune_nom,
        commune_insee,
        count(*) filter( WHERE numero != '99999') nb_adresses_total,
        count(*) filter( WHERE numero != '99999' and certification_commune=1) nb_adresses_certifiees,
        count(*) filter( WHERE numero != '99999' and  source='commune' ) nb_adresses_source_commune,
        min(date_der_maj) date_premiere_maj,
        max(date_der_maj) date_derniere_maj,
        coalesce(max(date_der_maj)::date - min(date_der_maj)::date,0) duree_maj_en_nb_de_jour
    FROM
        bal
    GROUP BY
        commune_nom, commune_insee
),
-- 1er indicateur : le nombre de date distinctes de mise à jour
nb_dates_distinctes as ( 
    SELECT distinct * FROM ( 
        SELECT 
            commune_nom,
            commune_insee,
            count(*) over( partition by commune_insee, date_der_maj ) as nb_adresses_modifiees,
            date_der_maj
        FROM
            bal
    ) requete_intermediaire
),
nb_dates_distinctes_par_commune as ( -- regroupement et decompte par commune
    SELECT 
        commune_nom, 
        commune_insee,
        count(*) -1 nb_dates_distinctes -- retire le jour de la mise à jour
    FROM 
        nb_dates_distinctes
    GROUP BY  
        commune_nom, commune_insee
    order by
        nb_dates_distinctes desc
),
-- deuxième indicateur : nombre d'adresses modifiées depuis moins de 2 ans, et en dehors de la date de 1ere publication
nb_adresse_modifiees as ( 
    SELECT distinct * FROM ( 
        SELECT 
            bal.commune_nom,
            bal.commune_insee,
            count(*)  over( partition by bal.commune_insee) nb_adresses_modifiees_recement
        FROM
            bal 
            INNER JOIN indicateurs_de_base_par_commune indicateur on indicateur.commune_insee = bal.commune_insee 
        WHERE
            numero != '99999'
            and
            date_der_maj is not null 
            and 
            date_der_maj > now() - interval '2 year'
    ) requete_intermediaire
),
-- troisième indicateur : nombre d'adresses qui sont en doublon de position géographique "geodoublon"
nb_adresses_geodoublon as (
    SELECT 
        commune_nom,
        commune_insee,
        count(*)  nb_adresses_geodoublon
    FROM
        bal 
    WHERE  
        numero != '99999'
    GROUP BY
        bal.commune_nom, commune_insee, bal.x::text || bal.y::text
    HAVING
      count(*) > 1
),
nb_adresses_geodoublon_par_commune as ( -- decompte par commune
    SELECT 
        commune_nom, 
        commune_insee,
        sum(nb_adresses_geodoublon) nb_adresses_geodoublon
    FROM
        nb_adresses_geodoublon
    GROUP BY
        commune_nom, commune_insee      
),
-- quatrième indicateur : nombre d'adresses qui sont en doublon "sémantique" : meme commune/lieu dit/voie/numero/suffixe/position
nb_adresses_doublon_semantique as (
    SELECT 
        commune_nom,
        commune_insee,
        count(*)  nb_adresses_doublon_semantique
    FROM
        bal 
    WHERE  
        numero != '99999'
    GROUP BY
        numero, suffixe, position, voie_nom, lieudit_complement_nom, commune_insee, commune_nom
    HAVING
      count(*) > 1
),
nb_adresses_doublon_semantique_par_commune as ( -- decompte par commune
    SELECT 
        commune_nom, 
        commune_insee,
        sum(nb_adresses_doublon_semantique) nb_adresses_doublon_semantique
    FROM
        nb_adresses_doublon_semantique
    GROUP BY
        commune_nom, commune_insee      
),
-- regroupe tous les indicateurs 
indicateurs_tous as (
    SELECT
        indicateurs_de_base.*,
        coalesce(nb_dates_distinctes_par_commune.nb_dates_distinctes, 0) nb_dates_distinctes,
        coalesce(nb_adresse_modifiees.nb_adresses_modifiees_recement, 0) nb_adresses_modifiees_recement,
        coalesce(nb_adresses_geodoublon_par_commune.nb_adresses_geodoublon, 0) nb_geodoublons,
        coalesce(nb_adresses_doublon_semantique_par_commune.nb_adresses_doublon_semantique, 0) nb_adresses_doublon_semantique,
        round(geo_commune.superficie_cadastrale / 100, 1) surface_commune_km2, -- surface en ha dans referentiel cadastral
        round(indicateurs_de_base.nb_adresses_total * 100.0 / (geo_commune.population + 1) ) nb_adresses_pour_100_habitants, -- rajoute 1 car il y a 6 communes avec une population de zéro habitants
        geo_commune.population population,
        geo_commune.classement,
        geo_commune.geom
    FROM
        indicateurs_de_base_par_commune indicateurs_de_base
            LEFT JOIN nb_dates_distinctes_par_commune on nb_dates_distinctes_par_commune.commune_insee = indicateurs_de_base.commune_insee
            LEFT JOIN nb_adresse_modifiees on nb_adresse_modifiees.commune_insee = indicateurs_de_base.commune_insee
            LEFT JOIN nb_adresses_geodoublon_par_commune on nb_adresses_geodoublon_par_commune.commune_insee = indicateurs_de_base.commune_insee
            LEFT JOIN nb_adresses_doublon_semantique_par_commune on nb_adresses_doublon_semantique_par_commune.commune_insee = indicateurs_de_base.commune_insee
            INNER JOIN 
                referentiel_communal geo_commune -- A MODIFIER SELON LA TABLE CONTENANT LA GEOMETRIE DES COMMUNES
                on geo_commune.code_insee = indicateurs_de_base.commune_insee::text -- A MODIFIER SELON le nom du champs code insee de la commune
),
-- indicateur agrégé
indicateurs_agrege AS (
    SELECT
        -- indicateur agrégé
        round( 
            --modifications recentes
            case when classement in ('Rural à habitat dispersé', 'Rural à habitat très dispersé' ) then 
                ( greatest( coalesce(log(10, "nb_adresses_modifiees_recement" + 0.00001 ),0),0) * 5  ) * 1.40
            else 
                ( greatest( coalesce(log(10, "nb_adresses_modifiees_recement" + 0.00001 ),0),0) * 5  ) * 1.0
            end
            +
            -- 100% modifie recemment, petite penalite car s'apparente a une mise a jour en masse sans distinction
            case when  "nb_adresses_modifiees_recement" !=  "nb_adresses_total" then 0 else -3 end
            +
            -- duree des mises à jour, plus les mises a sont etalee dans le temps, plus la base est a priori vivante
           ( greatest( coalesce(log(180,"duree_maj_en_nb_de_jour" + 0.00001 ),0),0) * 9 )  * 0.5
            + 
            -- nombre de date distinctes de mises à jour, plus il y en a, plus la mise a jour est reguliere et suivie
            case when classement in ('Rural à habitat dispersé', 'Rural à habitat très dispersé' ) then 
              ( greatest( coalesce(log( 5, "nb_dates_distinctes" + 0.0001 ),0),0) * 6 )   * 2.0
            else 
              ( greatest( coalesce(log( 5, "nb_dates_distinctes" + 0.0001 ),0),0) * 6 )   * 1.0
            end
            +
            -- nombre d'adresses certifiées
            ( "nb_adresses_certifiees" * 1.0 /  ( "nb_adresses_total" + 00000.1) * 10.0 )  * 2.0
            -- pénalite s'il y a des geodoublons
            -  
            case when classement in ('Rural à habitat dispersé', 'Rural à habitat très dispersé' ) then 
              ( greatest( coalesce(log(10, "nb_geodoublons" + 0.00001 ),0),0) * 7.0  )  *  3.0
            when classement in ('Bourgs ruraux ', 'Ceintures urbaines', 'Petites villes' ) then
              ( greatest( coalesce(log(10, "nb_geodoublons" + 0.00001 ),0),0) * 7.0  )  *  1.7
            else
              ( greatest( coalesce(log(10, "nb_geodoublons" + 0.00001 ),0),0) * 7.0  )  *  1.0
            end
            -- pénalité s'il y a des doublons sémantiques
            - 
            case when classement in ('Rural à habitat dispersé', 'Rural à habitat très dispersé' ) then 
              ( greatest( coalesce(log(10, "nb_adresses_doublon_semantique" + 0.00001 ),0),0) * 7.0  )  *  3.5
            when classement in ('Bourgs ruraux ', 'Ceintures urbaines', 'Petites villes' ) then
              ( greatest( coalesce(log(10, "nb_adresses_doublon_semantique" + 0.00001 ),0),0) * 7.0  )  *  2.0
            else
              ( greatest( coalesce(log(10, "nb_adresses_doublon_semantique" + 0.00001 ),0),0) * 7.0  )  *  1.0
            end
            -- pénalité s'il y a une densité d'adresse trop faible
            - 
            case when classement in ('Rural à habitat dispersé', 'Rural à habitat très dispersé' ) then 
              ( 25 - least( "nb_adresses_pour_100_habitants", 50  )  * 0.2 )  
            when classement in ('Bourgs ruraux' ) then 
              ( 20 - least( "nb_adresses_pour_100_habitants", 40  )  * 0.25 ) 
            when classement in ('Petites villes' ) then 
              ( 18 - least( "nb_adresses_pour_100_habitants", 36  )  * 0.27 ) 
            when classement in ('Ceintures urbaines' ) then 
              ( 15 - least( "nb_adresses_pour_100_habitants", 30  )  * 0.33 )  
            when classement in ('Centres urbains intermédiaires' ) then 
              ( 12 - least( "nb_adresses_pour_100_habitants", 24  )  * 0.41 ) 
            when classement in ('Grands centres urbains' ) then 
              ( 7.5 - least( "nb_adresses_pour_100_habitants", 15  )  * 0.66 )               
            end            
            +
            (  "nb_adresses_source_commune"  * 1.0 /  ( "nb_adresses_total" + 00000.1)   * 5 )
        )::integer as indicateur_aggrege,
        indicateurs_tous.*
    FROM
        indicateurs_tous
)
-- on insert dans la table
INSERT INTO ban_qualite.bal_indicateurs
    (commune_insee, commune_nom, classement,
    nb_adresses_total, nb_adresses_certifiees, nb_adresses_source_commune,
    date_premiere_maj, date_derniere_maj, nb_dates_distinctes, 
    duree_maj_en_nb_de_jour, nb_adresses_modifiees_recement, 
    nb_geodoublons, 
    nb_adresses_doublon_semantique,
    nb_adresses_pour_100_habitants,
    indicateur_aggrege,
    surface_commune_km2,
    population,
    geom)
SELECT
    commune_insee, commune_nom, classement,
    nb_adresses_total, nb_adresses_certifiees, nb_adresses_source_commune,
    date_premiere_maj, date_derniere_maj, nb_dates_distinctes, 
    duree_maj_en_nb_de_jour, nb_adresses_modifiees_recement, 
    nb_geodoublons, 
    nb_adresses_doublon_semantique,
    nb_adresses_pour_100_habitants,
    least( greatest(indicateur_aggrege, 0), 100),  -- limite indicateur entre 0 et 100 , 
    surface_commune_km2, 
    population,
    geom
FROM indicateurs_agrege 
;
