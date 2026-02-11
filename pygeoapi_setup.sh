#!/bin/bash

# on s'arrête si qqch se passe mal
set -e

source .venv/bin/activate

cp -f installation/pygeoapi_config.yml pygeoapi/config.yml

cd pygeoapi/

pygeoapi openapi generate config.yml --output-file openapi.yml

pygeoapi openapi validate openapi.yml

deactivate
