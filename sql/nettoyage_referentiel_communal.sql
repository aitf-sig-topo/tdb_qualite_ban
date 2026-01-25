-- Nettoie la geometry de la table des contour de commune (geometrie non typee)
-- script lancé après l'import ogr2ogr du geojson des contours communaux

-- rajoute colomne geometrie typee
ALTER TABLE IF EXISTS referentiel_communal
        ADD COLUMN geom public.geometry(MultiPolygon,2154);


-- copie géometrie non typée vers geométrie typée
UPDATE referentiel_communal set geom = ST_Multi(st_transform(geom_org, 2154)); 

-- supprime colonne géométrie non typée
ALTER TABLE referentiel_communal drop column geom_org ;

-- des indexes
CREATE UNIQUE INDEX referentiel_communal_code_insee_idx ON referentiel_communal (code_insee);
CREATE INDEX referentiel_communal_geom_idx ON referentiel_communal USING gist (geom);
