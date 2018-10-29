#!/bin/sh
set -e

helm init --client-only

helm repo add charts http://127.0.0.1:8879/charts
helm repo update

helm install --name ingress --namespace ingress charts/nginx-ingress --wait
helm install --name cert-manager --namespace cert-manager charts/cert-manager --wait

helm install --name dashboard --namespace kube-system charts/kubernetes-dashboard --wait

helm install --name prometheus-operator --namespace monitoring charts/prometheus-operator --wait
helm install --name kube-prometheus --namespace monitoring charts/kube-prometheus --wait

helm install --name grafana --namespace dashboard charts/grafana --wait
