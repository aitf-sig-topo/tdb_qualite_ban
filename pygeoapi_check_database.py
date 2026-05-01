#!/usr/bin/env python3
"""
Script de vérification de la configuration PostgreSQL/PostGIS
pour pygeoapi - Tuiles vecteur BAN

Ce script vérifie :
- La connexion à la base de données
- L'existence de la table
- La structure de la table (colonnes)
- La présence d'une colonne géométrique
- Le système de coordonnées
- Les index spatiaux
- Le nombre d'enregistrements
"""

import sys
import psycopg2
from psycopg2.extras import RealDictCursor


class DatabaseChecker:
    def __init__(self, host, port, dbname, user, password, schema, table):
        self.host = host
        self.port = port
        self.dbname = dbname
        self.user = user
        self.password = password
        self.schema = schema
        self.table = table
        self.conn = None
        
    def connect(self):
        """Établir la connexion à la base de données"""
        try:
            self.conn = psycopg2.connect(
                host=self.host,
                port=self.port,
                dbname=self.dbname,
                user=self.user,
                password=self.password
            )
            print(f"✓ Connexion réussie à la base de données '{self.dbname}'")
            return True
        except psycopg2.Error as e:
            print(f"✗ Erreur de connexion : {e}")
            return False
    
    def check_table_exists(self):
        """Vérifier que la table existe"""
        try:
            with self.conn.cursor() as cur:
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = %s 
                        AND table_name = %s
                    );
                """, (self.schema, self.table))
                exists = cur.fetchone()[0]
                
                if exists:
                    print(f"✓ La table '{self.schema}.{self.table}' existe")
                    return True
                else:
                    print(f"✗ La table '{self.schema}.{self.table}' n'existe pas")
                    return False
        except psycopg2.Error as e:
            print(f"✗ Erreur lors de la vérification de la table : {e}")
            return False
    
    def get_columns_info(self):
        """Obtenir les informations sur les colonnes"""
        try:
            with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT 
                        column_name,
                        data_type,
                        is_nullable,
                        column_default
                    FROM information_schema.columns
                    WHERE table_schema = %s 
                    AND table_name = %s
                    ORDER BY ordinal_position;
                """, (self.schema, self.table))
                
                columns = cur.fetchall()
                
                if columns:
                    print(f"\n✓ Colonnes de la table '{self.schema}.{self.table}' :")
                    print("-" * 80)
                    print(f"{'Nom de la colonne':<30} {'Type':<20} {'Nullable':<10}")
                    print("-" * 80)
                    
                    for col in columns:
                        print(f"{col['column_name']:<30} {col['data_type']:<20} {col['is_nullable']:<10}")
                    
                    return columns
                else:
                    print(f"✗ Aucune colonne trouvée")
                    return []
                    
        except psycopg2.Error as e:
            print(f"✗ Erreur lors de la récupération des colonnes : {e}")
            return []
    
    def get_geometry_column(self):
        """Identifier la colonne géométrique"""
        try:
            with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT 
                        f_geometry_column as geom_column,
                        coord_dimension,
                        srid,
                        type as geom_type
                    FROM geometry_columns
                    WHERE f_table_schema = %s
                    AND f_table_name = %s;
                """, (self.schema, self.table))
                
                geom_info = cur.fetchone()
                
                if geom_info:
                    print(f"\n✓ Colonne géométrique trouvée :")
                    print(f"  - Nom : {geom_info['geom_column']}")
                    print(f"  - Type : {geom_info['geom_type']}")
                    print(f"  - Dimensions : {geom_info['coord_dimension']}D")
                    print(f"  - SRID : {geom_info['srid']}")
                    
                    # Convertir SRID en URL CRS pour pygeoapi
                    srid = geom_info['srid']
                    if srid == 4326:
                        crs_url = "http://www.opengis.net/def/crs/OGC/1.3/CRS84"
                        print(f"  - CRS URL : {crs_url}")
                    else:
                        crs_url = f"http://www.opengis.net/def/crs/EPSG/0/{srid}"
                        print(f"  - CRS URL : {crs_url}")
                    
                    return geom_info
                else:
                    print(f"\n✗ Aucune colonne géométrique trouvée dans geometry_columns")
                    print("  Recherche de colonnes de type géométrie...")
                    
                    # Tentative de trouver des colonnes géométriques via information_schema
                    cur.execute("""
                        SELECT column_name 
                        FROM information_schema.columns
                        WHERE table_schema = %s 
                        AND table_name = %s
                        AND udt_name = 'geometry';
                    """, (self.schema, self.table))
                    
                    geom_cols = cur.fetchall()
                    if geom_cols:
                        print(f"  Colonnes de type geometry trouvées : {[col['column_name'] for col in geom_cols]}")
                    
                    return None
                    
        except psycopg2.Error as e:
            print(f"✗ Erreur lors de la recherche de la colonne géométrique : {e}")
            return None
    
    def check_spatial_index(self, geom_column):
        """Vérifier la présence d'un index spatial"""
        try:
            with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT 
                        i.relname as index_name,
                        am.amname as index_type
                    FROM pg_class t
                    JOIN pg_index ix ON t.oid = ix.indrelid
                    JOIN pg_class i ON i.oid = ix.indexrelid
                    JOIN pg_am am ON i.relam = am.oid
                    JOIN pg_namespace n ON t.relnamespace = n.oid
                    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
                    WHERE n.nspname = %s
                    AND t.relname = %s
                    AND a.attname = %s
                    AND am.amname = 'gist';
                """, (self.schema, self.table, geom_column))
                
                indexes = cur.fetchall()
                
                if indexes:
                    print(f"\n✓ Index spatial(aux) trouvé(s) sur '{geom_column}' :")
                    for idx in indexes:
                        print(f"  - {idx['index_name']} (type: {idx['index_type']})")
                    return True
                else:
                    print(f"\n⚠ Aucun index spatial trouvé sur '{geom_column}'")
                    print("  Recommandation : créer un index GIST pour améliorer les performances")
                    print(f"  SQL : CREATE INDEX {self.table}_{geom_column}_idx ON {self.schema}.{self.table} USING GIST ({geom_column});")
                    return False
                    
        except psycopg2.Error as e:
            print(f"✗ Erreur lors de la vérification de l'index spatial : {e}")
            return False
    
    def get_record_count(self):
        """Compter le nombre d'enregistrements"""
        try:
            with self.conn.cursor() as cur:
                cur.execute(f"""
                    SELECT COUNT(*) FROM {self.schema}.{self.table};
                """)
                count = cur.fetchone()[0]
                print(f"\n✓ Nombre d'enregistrements : {count:,}")
                
                if count == 0:
                    print("  ⚠ La table est vide !")
                
                return count
                
        except psycopg2.Error as e:
            print(f"✗ Erreur lors du comptage des enregistrements : {e}")
            return None
    
    def get_extent(self, geom_column):
        """Obtenir l'emprise spatiale des données"""
        try:
            with self.conn.cursor() as cur:
                cur.execute(f"""
                    SELECT 
                        ST_XMin(extent) as xmin,
                        ST_YMin(extent) as ymin,
                        ST_XMax(extent) as xmax,
                        ST_YMax(extent) as ymax
                    FROM (
                        SELECT ST_Extent({geom_column}) as extent 
                        FROM {self.schema}.{self.table}
                    ) as subquery;
                """)
                
                extent = cur.fetchone()
                
                if extent and extent[0]:
                    print(f"\n✓ Emprise spatiale (bbox) :")
                    print(f"  [{extent[0]:.6f}, {extent[1]:.6f}, {extent[2]:.6f}, {extent[3]:.6f}]")
                    print(f"  Format pygeoapi : bbox: [{extent[0]:.6f}, {extent[1]:.6f}, {extent[2]:.6f}, {extent[3]:.6f}]")
                    return extent
                else:
                    print(f"\n⚠ Impossible de calculer l'emprise spatiale")
                    return None
                    
        except psycopg2.Error as e:
            print(f"✗ Erreur lors du calcul de l'emprise : {e}")
            return None
    
    def suggest_id_field(self, columns):
        """Suggérer un champ ID approprié"""
        print(f"\n✓ Suggestion pour id_field :")
        
        # Rechercher des colonnes qui pourraient être des ID
        potential_ids = []
        for col in columns:
            col_name = col['column_name'].lower()
            if any(keyword in col_name for keyword in ['id', 'gid', 'objectid', 'fid', 'code']):
                potential_ids.append(col['column_name'])
        
        if potential_ids:
            print(f"  Colonnes candidates : {', '.join(potential_ids)}")
            print(f"  Recommandation : utilisez '{potential_ids[0]}'")
        else:
            print(f"  ⚠ Aucune colonne ID évidente trouvée")
            print(f"  Assurez-vous d'avoir une colonne avec des valeurs uniques")
    
    def generate_config_snippet(self, geom_info, id_field='id'):
        """Générer un extrait de configuration pour pygeoapi"""
        print(f"\n" + "="*80)
        print("Configuration suggérée pour pygeoapi :")
        print("="*80)
        
        if geom_info:
            geom_column = geom_info['geom_column']
            srid = geom_info['srid']
            
            if srid == 4326:
                storage_crs = "http://www.opengis.net/def/crs/OGC/1.3/CRS84"
            else:
                storage_crs = f"http://www.opengis.net/def/crs/EPSG/0/{srid}"
            
            config = f"""
providers:
    - type: tile
      name: MVT-postgresql
      data:
          host: {self.host}
          port: {self.port}
          dbname: {self.dbname}
          user: {self.user}
          password: {self.password}
          search_path: [{self.schema}, public]
      id_field: {id_field}  # À vérifier selon votre table
      table: {self.table}
      geom_field: {geom_column}
      storage_crs: {storage_crs}
      options:
          zoom:
              min: 0
              max: 16
      format:
          name: pbf
          mimetype: application/vnd.mapbox-vector-tile
"""
            print(config)
        else:
            print("⚠ Impossible de générer la configuration (géométrie non trouvée)")
    
    def run_all_checks(self):
        """Exécuter toutes les vérifications"""
        print("\n" + "="*80)
        print("Vérification de la configuration PostgreSQL/PostGIS pour pygeoapi")
        print("="*80 + "\n")
        
        if not self.connect():
            return False
        
        if not self.check_table_exists():
            return False
        
        columns = self.get_columns_info()
        if not columns:
            return False
        
        geom_info = self.get_geometry_column()
        
        if geom_info:
            self.check_spatial_index(geom_info['geom_column'])
            self.get_extent(geom_info['geom_column'])
        
        self.get_record_count()
        
        self.suggest_id_field(columns)
        
        self.generate_config_snippet(geom_info)
        
        print("\n" + "="*80)
        print("Vérification terminée !")
        print("="*80 + "\n")
        
        return True
    
    def close(self):
        """Fermer la connexion"""
        if self.conn:
            self.conn.close()


def main():
    # Configuration de la base de données
    config = {
        'host': 'aitf-ban.breizhpositive.bzh',
        'port': 5432,
        'dbname': 'ban',
        'user': 'aitf_admin',
        'password': 'vivelaterritoriale',
        'schema': 'ban_qualite',
        'table': 'bal_indicateurs'
    }
    
    print("\nConfiguration utilisée :")
    print(f"  Hôte : {config['host']}:{config['port']}")
    print(f"  Base de données : {config['dbname']}")
    print(f"  Table : {config['schema']}.{config['table']}")
    
    checker = DatabaseChecker(**config)
    
    try:
        checker.run_all_checks()
    except KeyboardInterrupt:
        print("\n\nInterrompu par l'utilisateur")
    except Exception as e:
        print(f"\n✗ Erreur inattendue : {e}")
        import traceback
        traceback.print_exc()
    finally:
        checker.close()


if __name__ == "__main__":
    main()
