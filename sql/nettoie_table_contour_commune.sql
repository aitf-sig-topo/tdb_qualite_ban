-- Nettoie la geometry de la table des contour de commune (geometrie non typee)
-- script lancé après l'import ogr2ogr du geojson des contours communaux

-- rajoute colomne geometrie typee
ALTER TABLE IF EXISTS commune_contour
        ADD COLUMN geom public.geometry(MultiPolygon,2154);


-- copie géometrie non typée vers geométrie typée
UPDATE commune_contour set geom = ST_Multi(geom_org); 

-- supprime colonne géométrie non typée
ALTER TABLE commune_contour drop column geom_org ;

-- des indexes
CREATE UNIQUE INDEX commune_contour_codgeo_idx ON commune_contour (codgeo);
CREATE INDEX commune_contour_geom_idx ON commune_contour USING gist (geom);
