#!/bin/sh
set -e

sudo apt install postgresql postgresql-postgis -y
sudo apt install gdal-bin -y

psql --version
ogr2ogr --version

