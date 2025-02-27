#!/bin/bash
set -e

if [ -z "$REPO" ]; then
  if [ -z "$1" ]; then
    echo "Usage: $0 <github-repo>"
    exit 1
  else
    REPO=$1
  fi
fi

echo "Using GitHub repo: $REPO"

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

PULL_REQUESTS_URL="https://github.com/$REPO/pulls"
BOX_WIDTH=$((${#PULL_REQUESTS_URL} + 19))
echo $(printf '#%.0s' $(seq 1 $BOX_WIDTH))
echo "# Pull Requests: $PULL_REQUESTS_URL #"
echo $(printf '#%.0s' $(seq 1 $BOX_WIDTH))

exec docker run -it --rm -v $(pwd):/work -w /work gomerge list -t $GITHUB_TOKEN --merge-method rebase -r $REPO $LABELS_ARG
