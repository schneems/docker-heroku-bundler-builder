#!/bin/bash

OUTPUT_DIR=${OUTPUT_DIR:-`pwd`/builds}
CACHE_DIR=${CACHE_DIR:-`pwd`/cache}

echo "OUTPUT DIR: $OUTPUT_DIR"
echo "CACHE DIR:  $CACHE_DIR"

docker build -t schneems/bundler-builder:heroku-18 .
docker run -v $OUTPUT_DIR:/tmp/output -v $CACHE_DIR:/tmp/cache -e VERSION=2.5.3  -e STACK=heroku-18 schneems/bundler-builder:heroku-18

# https://rubygems.org/api/v1/versions/coulda.json
