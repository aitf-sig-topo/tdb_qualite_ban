
-- calcul des indicateurs a partir de la table bal_brute et copie du résultat dans une table bal_indicateurs
with
bal as ( 
    -- csv bal importé dans postgresql 
	select 
		* 
	from 
		bal_brute
	where 
		numero != '99999' -- ignore numero specifique
),
-- indicateurs simples sur les communes (servironts aux autres indicateurs)
indicateurs_de_base_par_commune as (
	select 
		commune_nom,
		commune_insee,
		count(*) nb_adresses_total,
		count(*) filter( where certification_commune=1) nb_adresses_certifiees,
		count(*) filter( where source='commune' ) nb_adresses_source_commune,
		min(date_der_maj) date_premiere_maj,
		max(date_der_maj) date_derniere_maj,
		coalesce(max(date_der_maj)::date - min(date_der_maj)::date,0) duree_maj_en_nb_de_jour
	from
		bal
	group by
		commune_nom, commune_insee
),
-- 1er indicateur : le nombre de date distinctes de mise à jour
nb_dates_distinctes as ( 
	select distinct * from ( 
		select 
			commune_nom,
			commune_insee,
			count(*)  over( partition by commune_insee) nb_adresses_total,
			count(*) over( partition by commune_insee, date_der_maj ) as nb_adresses_modifiees,
			date_der_maj
		from
			bal
	) requete_intermediaire
),
nb_dates_distinctes_par_commune as ( -- regroupement et decompte par commune
	select 
		commune_nom, 
		commune_insee,
		-- nb_adresses_total,
		count(*) -1 nb_dates_distinctes -- retire le jour de la mise à jour
		-- min(date_der_maj) date_ancienne_modif,
		-- max(date_der_maj) date_derniere_modif,
		-- max(date_der_maj)::date - min(date_der_maj)::date periode_de_saisie_en_nb_de_jour
		-- count(*)::real * 100.0 / greatest(1, max(date_der_maj)::date - min(date_der_maj)::date ) as coef_nb_jours_avec_mise_a_jour
	from 
		nb_dates_distinctes
	group by  
		commune_nom, commune_insee
	order by
		nb_dates_distinctes desc
),
-- deuxième indicateur : nombre d'adresses modifiées depuis moins de 2 ans, et en dehors de la date de 1ere publication
nb_adresse_modifiees as ( 
	select distinct * from ( 
		select 
			bal.commune_nom,
			bal.commune_insee,
			-- indicateur.nb_adresses_total,
			count(*)  over( partition by bal.commune_insee) nb_adresses_modifiees_recement
			-- bal.date_der_maj
		from
			bal 
			inner join indicateurs_de_base_par_commune indicateur on indicateur.commune_insee = bal.commune_insee 
		where
			date_der_maj is not null 
			and 
			date_der_maj > now() - interval '2 year'
	) requete_intermediaire
),
-- troisième indicateur : nombre d'adresses qui sont en doublon de position géographique "geodoublon"
nb_adresses_geodoublon as (
	select 
		commune_nom,
		commune_insee,
		count(*)  nb_adresses_geodoublon
	from
		bal 
	group by
		bal.commune_nom, commune_insee, bal.x::text || bal.y::text
	having
	  count(*) > 1
),
nb_adresses_geodoublon_par_commune as ( -- decompte par commune
	select 
		commune_nom, 
		commune_insee,
		sum(nb_adresses_geodoublon) nb_adresses_geodoublon
	from
		nb_adresses_geodoublon
	group by
		commune_nom, commune_insee		
)
-- synthèse de tous les indicateurs 
select
	indicateurs_de_base.*,
	coalesce(nb_dates_distinctes_par_commune.nb_dates_distinctes, 0) nb_dates_distinctes,
	coalesce(nb_adresse_modifiees.nb_adresses_modifiees_recement, 0) nb_adresses_modifiees_recement,
	coalesce(nb_adresses_geodoublon_par_commune.nb_adresses_geodoublon, 0) nb_geodoublons,
    st_area(geo_commune.geom)/1000000.0 surface_commune_km2,
	geo_commune.geom
into
	temp.bal_indicateurs -- A MODIFIER selon le nom souhaité pour la table en sortie des indicateurs
from
	indicateurs_de_base_par_commune indicateurs_de_base
		left join nb_dates_distinctes_par_commune on nb_dates_distinctes_par_commune.commune_insee = indicateurs_de_base.commune_insee
		left join nb_adresse_modifiees on nb_adresse_modifiees.commune_insee = indicateurs_de_base.commune_insee
		left join nb_adresses_geodoublon_par_commune on nb_adresses_geodoublon_par_commune.commune_insee = indicateurs_de_base.commune_insee
        inner join 
			communes geo_commune -- A MODIFIER SELON LA TABLE CONTENANT LA GEOMETRIE DES COMMUNES
			on geo_commune.codgeo = indicateurs_de_base.commune_insee::text -- A MODIFIER SELON le nom du champs code insee de la commune
;

