-- Nettoie la geometry de la table des contour de commune (geometrie non typee)
-- script lancé après l'import ogr2ogr du geojson des contours communaux

-- rajoute colomne geometrie typee
ALTER TABLE IF EXISTS commune_contour
        ADD COLUMN geom public.geometry(MultiPolygon,2154);


-- copie géometrie non typée vers geométrie typée        
update commune_contour set geom =  wkb_geometry; 

-- supprime colonne géométrie non typée
ALTER TABLE commune_contour drop column wkb_geometry ;
   
