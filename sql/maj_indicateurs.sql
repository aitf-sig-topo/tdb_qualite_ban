


-- calcul des indicateurs a partir de la table bal_brute et copie du résultat dans une table bal_indicateurs
WITH
bal as ( 
    -- csv bal importé dans postgresql 
    SELECT 
        * 
    FROM 
        bal_brute
    WHERE 
        numero != '99999' -- ignore numero specifique
        #where_clause#
),
-- indicateurs simples sur les communes (servironts aux autres indicateurs)
indicateurs_de_base_par_commune as (
    SELECT 
        commune_nom,
        commune_insee,
        count(*) nb_adresses_total,
        count(*) filter( WHERE certification_commune=1) nb_adresses_certifiees,
        count(*) filter( WHERE source='commune' ) nb_adresses_source_commune,
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
            count(*)  over( partition by commune_insee) nb_adresses_total,
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
        -- nb_adresses_total,
        count(*) -1 nb_dates_distinctes -- retire le jour de la mise à jour
        -- min(date_der_maj) date_ancienne_modif,
        -- max(date_der_maj) date_derniere_modif,
        -- max(date_der_maj)::date - min(date_der_maj)::date periode_de_saisie_en_nb_de_jour
        -- count(*)::real * 100.0 / greatest(1, max(date_der_maj)::date - min(date_der_maj)::date ) as coef_nb_jours_avec_mise_a_jour
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
            -- indicateur.nb_adresses_total,
            count(*)  over( partition by bal.commune_insee) nb_adresses_modifiees_recement
            -- bal.date_der_maj
        FROM
            bal 
            INNER JOIN indicateurs_de_base_par_commune indicateur on indicateur.commune_insee = bal.commune_insee 
        WHERE
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
-- regroupe tous les indicateurs 
indicateurs_tous as (
    SELECT
        indicateurs_de_base.*,
        coalesce(nb_dates_distinctes_par_commune.nb_dates_distinctes, 0) nb_dates_distinctes,
        coalesce(nb_adresse_modifiees.nb_adresses_modifiees_recement, 0) nb_adresses_modifiees_recement,
        coalesce(nb_adresses_geodoublon_par_commune.nb_adresses_geodoublon, 0) nb_geodoublons,
        public.st_area(geo_commune.geom)/1000000.0 surface_commune_km2,
        geo_commune.geom
    FROM
        indicateurs_de_base_par_commune indicateurs_de_base
            LEFT JOIN nb_dates_distinctes_par_commune on nb_dates_distinctes_par_commune.commune_insee = indicateurs_de_base.commune_insee
            LEFT JOIN nb_adresse_modifiees on nb_adresse_modifiees.commune_insee = indicateurs_de_base.commune_insee
            LEFT JOIN nb_adresses_geodoublon_par_commune on nb_adresses_geodoublon_par_commune.commune_insee = indicateurs_de_base.commune_insee
            INNER JOIN 
                commune_contour geo_commune -- A MODIFIER SELON LA TABLE CONTENANT LA GEOMETRIE DES COMMUNES
                on geo_commune.codgeo = indicateurs_de_base.commune_insee::text -- A MODIFIER SELON le nom du champs code insee de la commune
),
-- indicateur agrégé
indicateurs_agrege AS (
    SELECT
        -- indicateur agrégé
        round( 
            --modifications recentes
            case when "nb_adresses_modifiees_recement" = 0 then 0 else
              ( greatest( coalesce(log(10, "nb_adresses_modifiees_recement" ),0),0) * 5  )
            end
            +
            -- 100% modifie recemment, petite penalite car s'apparente a une mise a jour en masse sans distinction
            case when  "nb_adresses_modifiees_recement" !=  "nb_adresses_total" then 0 else -3 end
            +
            -- duree des mises à jour, plus les mises a sont etalee dans le temps, plus la base est a priori vivante
            case when "duree_maj_en_nb_de_jour" = 0 then 0 else
              ( greatest( coalesce(log(180,"duree_maj_en_nb_de_jour"),0),0) * 2 )
            end
            + 
            -- nombre de date distinctes de mises à jour, plus il y en a, plus la mise a jour est reguliere et suivie
            case when  "nb_dates_distinctes" = 0 then 0 else
              ( greatest( coalesce(log( 5, "nb_dates_distinctes"),0),0) * 5 )
            end
            +
            ( "nb_adresses_certifiees" * 1.0 /  "nb_adresses_total"   * 20 )
            -- penalite s'il y a des geodoublons
            - 
            case when "nb_geodoublons" = 0 then 0 else
              ( greatest( coalesce(log(10, "nb_geodoublons" ),0),0)  )
            end
            +
            (  "nb_adresses_source_commune"  * 1.0 /  "nb_adresses_total"   * 5 )
        )::integer as indicateur_aggrege,
        indicateurs_tous.*
    FROM
        indicateurs_tous
)
-- on insert dans la table
INSERT INTO ban_qualite.bal_indicateurs
    (commune_insee, commune_nom, 
    nb_adresses_total, nb_adresses_certifiees, nb_adresses_source_commune,
    date_premiere_maj, date_derniere_maj, nb_dates_distinctes, 
    duree_maj_en_nb_de_jour, nb_adresses_modifiees_recement, 
    nb_geodoublons, 
    indicateur_aggrege, 
    surface_commune_km2, geom)
SELECT
    commune_insee, commune_nom,
    nb_adresses_total, nb_adresses_certifiees, nb_adresses_source_commune,
    date_premiere_maj, date_derniere_maj, nb_dates_distinctes, 
    duree_maj_en_nb_de_jour, nb_adresses_modifiees_recement, 
    nb_geodoublons, 
    indicateur_aggrege, 
    surface_commune_km2, geom
FROM indicateurs_agrege a
;
