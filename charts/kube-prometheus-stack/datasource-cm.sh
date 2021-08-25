cat <<EOT > loki-datasource.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-grafana-datasource
  labels:
     grafana_datasource: "1"
     namespace: monitoring
data:
  datasource-loki.yaml: |-
    apiVersion: 1
    datasources:
    - name: Loki
      type: loki
      url: http://loki:3100/
      access: proxy
      isDefault: false
      version: 1
EOT