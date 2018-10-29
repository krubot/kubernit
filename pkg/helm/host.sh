#!/bin/sh
set -e

for chart in $(ls charts/); do
  helm package charts/$chart
done

helm repo index --url http://127.0.0.1:8879/charts .
helm serve --repo-path . --address 127.0.0.1:8879 --url http://127.0.0.1:8879/charts
