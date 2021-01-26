cat <<EOT > prometheus-datasource-values.yaml
grafana:
  additionalDataSources:
    - name: prometheus
      type: prometheus
      url: http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090
      access: proxy
      isDefault: true
EOT