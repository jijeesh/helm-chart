cat <<EOT > grafana-datasources-values.yaml
grafana:
  additionalDataSources:
    - name: Loki
      type: loki
      url: http://loki:3100/
      access: proxy
      isDefault: false
EOT