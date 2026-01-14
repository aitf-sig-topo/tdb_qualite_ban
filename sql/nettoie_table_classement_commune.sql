-- cree la table insee de classement car fichier d'import ne met pas les champs en premiere ligne

SET search_path TO ban_qualite, public;

CREATE UNIQUE INDEX commune_classement_idx ON commune_classement (codgeo);
