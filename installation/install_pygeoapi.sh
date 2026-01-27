#!/bin/bash

# on s'arrête si qqch se passe mal
set -e

cd ..

# on utilise le Python 3.12 installé manuellement
PYTHON=/usr/local/bin/python3.12

# création d'un venv
$PYTHON -m venv .venv
source .venv/bin/activate


git clone https://github.com/geopython/pygeoapi.git

cd pygeoapi/

pip install -r requirements.txt
pip install .

cp pygeoapi-config.yml example-config.yml
nano example-config.yml  # edit as required

deactivate

# sudo ufw allow 5000/tcp

