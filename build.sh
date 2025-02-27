#!/bin/sh
docker build -t gomerge . > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Docker build failed"
  exit 1
fi
