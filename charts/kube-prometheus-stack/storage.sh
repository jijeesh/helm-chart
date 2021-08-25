#!/bin/bash
retention=15d
retentionSize=8GiB
storage=10Gi
storage_enable=true
if [[ ! "$storage_enable" == "true" ]]
then
cat <<EOT > prometheus-storage-values.yaml
prometheus:
  prometheusSpec:
    retention: ${retention}
    retentionSize: ${retentionSize}
    scrapeInterv: 30s
    storageSpec: {}
EOT
else
cat <<EOT > prometheus-storage-values.yaml
prometheus:
  prometheusSpec:
    retention: ${retention}
    retentionSize: ${retentionSize}
    scrapeInterv: 30s
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: default
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: ${storage}
EOT
fi