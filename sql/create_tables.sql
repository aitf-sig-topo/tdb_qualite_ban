

SET search_path TO ban_qualite, public;


DROP TABLE IF EXISTS bal_brute ;

CREATE TABLE bal_brute
(
    uid_adresse text,
    cle_interop text,
    commune_insee character(5),
    commune_nom text,
    commune_deleguee_insee character(5),
    commune_deleguee_nom text,
    voie_nom text,
    lieudit_complement_nom text,
    numero bigint,
    suffixe text,
    "position" text,
    x double precision,
    y double precision,
    "long" double precision,
    lat double precision,
    cad_parcelles text,
    source text,
    date_der_maj date,
    certification_commune int
);
-- les indexes de cette table sont dans un fichier dédié



DROP TABLE IF EXISTS bal_indicateurs;

CREATE TABLE bal_indicateurs (
    commune_insee character(5) NOT NULL,
    commune_nom text NOT NULL,
    classement text NOT NULL,
    nb_adresses_total int8 NULL,
    nb_adresses_certifiees int8 NULL,
    nb_adresses_source_commune int8 NULL,
    date_premiere_maj date NULL,
    date_derniere_maj date NULL,
    nb_dates_distinctes int8 NULL,
    duree_maj_en_nb_de_jour int4 NULL,
    nb_adresses_modifiees_recement int8 NULL,
    nb_geodoublons numeric NULL,
    indicateur_aggrege int4 NULL,
    surface_commune_km2 float8 NULL,
    geom geometry(multipolygon, 2154) NULL
);

CREATE UNIQUE INDEX bal_indicateurs_commune_insee_idx ON bal_indicateurs (commune_insee);
CREATE INDEX bal_indicateurs_geom_idx ON bal_indicateurs USING gist (geom);

