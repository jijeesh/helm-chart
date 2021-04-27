#!/bin/bash -e
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kubectl config set-cluster cfc --server=https://kubernetes.default.svc.cluster.local --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
kubectl config set-context cfc --cluster=cfc
kubectl config set-credentials user --token=${TOKEN}
kubectl config set-context cfc --user=user
kubectl config use-context cfc