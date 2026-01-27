#!/bin/bash

# on s'arrête si qqch se passe mal
set -e

source .venv/bin/activate

cd pygeoapi/

export PYGEOAPI_CONFIG=config.yml
export PYGEOAPI_OPENAPI=openapi.yml

pygeoapi serve

# in another terminal
# curl http://localhost:5000  # or open in a web browser

deactivate

