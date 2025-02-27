#!/bin/bash

set -e

if [ -z "$ORG" ]; then
  if [ -z "$1" ]; then
    echo "Usage: $0 <github-organization>"
    exit 1
  else
    ORG=$1
  fi
fi

echo "Using GitHub organization: $ORG"

repos=$(gh repo list $ORG --no-archived --limit 500 --json name --jq '.[].name')

echo "Number of repositories: $(echo "$repos" | wc -w)"

for repo in $repos; do
  echo "Checking repository: $ORG/$repo"
  ./review-repo.sh "$ORG/$repo"
done
