
INSERT INTO bal_indicateurs_hist
    (hist_date,
    commune_insee, commune_nom, classement,
    nb_adresses_total, nb_adresses_certifiees, nb_adresses_source_commune,
    date_premiere_maj, date_derniere_maj, nb_dates_distinctes, 
    duree_maj_en_nb_de_jour, nb_adresses_modifiees_recement, 
    nb_geodoublons, 
    indicateur_aggrege, 
    surface_commune_km2, geom)
SELECT 
  max( coalesce(date_derniere_maj, '01-01-1970') ) over(), -- prend la date la plus récente des mises à jour dans la BAL
  commune_insee, commune_nom, classement,
  nb_adresses_total, nb_adresses_certifiees, nb_adresses_source_commune,
  date_premiere_maj, date_derniere_maj, nb_dates_distinctes, 
  duree_maj_en_nb_de_jour, nb_adresses_modifiees_recement, 
  nb_geodoublons, 
  indicateur_aggrege, 
  surface_commune_km2, geom
FROM bal_indicateurs
;
