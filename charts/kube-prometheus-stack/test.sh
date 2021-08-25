#helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --version 9.4.9 \
#                  -f linkerd_values.yaml -f prometheus-storage-values.yaml

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
 --namespace monitoring --version 9.4.9 \
 -f current_values.yaml -f linkerd-values.yaml -f grafana-datasources-values.yaml \
 -f prometheus-storage-values.yaml