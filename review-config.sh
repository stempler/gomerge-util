#!/bin/bash

#
# Start review process based on configuration file `config.yaml`.
# See https://github.com/Cian911/gomerge/tree/master?tab=readme-ov-file#bulk-mergingapprovingclosing-pull-requests
#

set -e

if [ ! -f config.yaml ]; then
  echo "Error: config.yaml not found."
  exit 1
fi

./build.sh

source ./.env

LABELS_ARG=""
if [ -n "$LABELS" ]; then
  echo "Using labels: \"$LABELS\""
  IFS=',' read -ra ADDR <<< "$LABELS"
  for label in "${ADDR[@]}"; do
    LABELS_ARG+=" --label $label"
  done
fi

exec docker run -it --rm -v $(pwd):/work -w /work gomerge list -t $GITHUB_TOKEN --merge-method rebase $LABELS_ARG -c config.yaml
