CREATE TABLE IF NOT EXISTS bal_indicateurs
(
    uid_adresse text COLLATE pg_catalog."default",
    cle_interop text COLLATE pg_catalog."default",
    commune_insee character(5),
    commune_nom text COLLATE pg_catalog."default",
    commune_deleguee_insee bigint,
    commune_deleguee_nom text COLLATE pg_catalog."default",
    voie_nom text COLLATE pg_catalog."default",
    lieudit_complement_nom text COLLATE pg_catalog."default",
    numero bigint,
    suffixe text COLLATE pg_catalog."default",
    "position" text COLLATE pg_catalog."default",
    x double precision,
    y double precision,
    "long" double precision,
    lat double precision,
    cad_parcelles text COLLATE pg_catalog."default",
    source text COLLATE pg_catalog."default",
    date_der_maj date,
    certification_commune bigint
);
