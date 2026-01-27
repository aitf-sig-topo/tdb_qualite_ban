#!/bin/bash

# on s'arrête si qqch se passe mal
set -e

source .venv/bin/activate

cp -f installation/pygeoapi_config.yml pygeoapi/config.yml

cd pygeoapi/

export PYGEOAPI_CONFIG=config.yml
export PYGEOAPI_OPENAPI=openapi.yml

pygeoapi openapi generate $PYGEOAPI_CONFIG --output-file $PYGEOAPI_OPENAPI

deactivate
