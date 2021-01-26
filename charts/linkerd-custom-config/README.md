# install Helm version
helm version
Helm users who use installCRDs=true MUST upgrade to Helm v3.3.1
```
helmVersion3=v3.5.0
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh --version v3.5.0
```

# install cert-manager
```
# Add the cert-manager Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Create a dedicated namespace where you would like to deploy cert-manager into
if [ "`kubectl get ns cert-manager -o name`" != 'namespace/cert-manager' ]; then
        echo 'Namespace cert-manager doesnt exists, creating'        
        kubectl create namespace cert-manager
fi

helm upgrade cert-manager --install \
   jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.1.0 \
  --set installCRDs=true
```

# install step-cli

```
wget https://github.com/smallstep/cli/releases/download/vX.Y.Z/step-cli_X.Y.Z_amd64.deb
sudo dpkg -i step-cli_X.Y.Z_amd64.deb

```
# Create Certificate for Control Plane 

```
step certificate create root.linkerd.cluster.local rootCA/ca.crt rootCA/ca.key \
  --profile root-ca --no-password --insecure
```
# Create Certificate for Webhook 
```
step certificate create webhook.linkerd.cluster.local webhookCA/ca.crt webhookCA/ca.key \
  --profile root-ca --no-password --insecure --san webhook.linkerd.cluster.local
```
# Create Namespace
```
# Create a dedicated namespace where you would like to deploy linkerd into
if [ "`kubectl get ns linkerd -o name`" != 'namespace/linkerd' ]; then
        echo 'Namespace linkerd doesnt exists, creating'        
        kubectl create namespace linkerd
fi

```
# Update prometheus with scrap config updateion

```
cat <<EOT > linkerd-values.yaml
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
      - job_name: 'linkerd-controller'

        scrape_interval: 10s
        scrape_timeout: 10s

        kubernetes_sd_configs:
        - role: pod
          namespaces:
            names: ['linkerd']
        relabel_configs:
        - source_labels:
          - __meta_kubernetes_pod_label_linkerd_io_control_plane_component
          - __meta_kubernetes_pod_container_port_name
          action: keep
          regex: (.*);admin-http$
        - source_labels: [__meta_kubernetes_pod_container_name]
          action: replace
          target_label: component

      - job_name: 'linkerd-service-mirror'

        scrape_interval: 10s
        scrape_timeout: 10s

        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels:
          - __meta_kubernetes_pod_label_linkerd_io_control_plane_component
          - __meta_kubernetes_pod_container_port_name
          action: keep
          regex: linkerd-service-mirror;admin-http$
        - source_labels: [__meta_kubernetes_pod_container_name]
          action: replace
          target_label: component

      - job_name: 'linkerd-proxy'

        scrape_interval: 10s
        scrape_timeout: 10s

        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels:
          - __meta_kubernetes_pod_container_name
          - __meta_kubernetes_pod_container_port_name
          - __meta_kubernetes_pod_label_linkerd_io_control_plane_ns
          action: keep
          regex: ^linkerd-proxy;linkerd-admin;linkerd$
        - source_labels: [__meta_kubernetes_namespace]
          action: replace
          target_label: namespace
        - source_labels: [__meta_kubernetes_pod_name]
          action: replace
          target_label: pod
        # special case k8s' "job" label, to not interfere with prometheus' "job"
        # label
        # __meta_kubernetes_pod_label_linkerd_io_proxy_job=foo =>
        # k8s_job=foo
        - source_labels: [__meta_kubernetes_pod_label_linkerd_io_proxy_job]
          action: replace
          target_label: k8s_job
        # drop __meta_kubernetes_pod_label_linkerd_io_proxy_job
        - action: labeldrop
          regex: __meta_kubernetes_pod_label_linkerd_io_proxy_job
        # __meta_kubernetes_pod_label_linkerd_io_proxy_deployment=foo =>
        # deployment=foo
        - action: labelmap
          regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
        # drop all labels that we just made copies of in the previous labelmap
        - action: labeldrop
          regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
        # __meta_kubernetes_pod_label_linkerd_io_foo=bar =>
        # foo=bar
        - action: labelmap
          regex: __meta_kubernetes_pod_label_linkerd_io_(.+)
        # Copy all pod labels to tmp labels
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
          replacement: __tmp_pod_label_$1
        # Take `linkerd_io_` prefixed labels and copy them without the prefix
        - action: labelmap
          regex: __tmp_pod_label_linkerd_io_(.+)
          replacement:  __tmp_pod_label_$1
        # Drop the `linkerd_io_` originals
        - action: labeldrop
          regex: __tmp_pod_label_linkerd_io_(.+)
        # Copy tmp labels into real labels
        - action: labelmap
          regex: __tmp_pod_label_(.+)

EOT
```
# Install custom linkerd configuration

This will install in two namespaces , monitoring and linkerd
```
helm upgrade --install linkerd-dashboad
```

# Install linkerd

```
# To add the repo for Linkerd2 stable releases:
helm repo add linkerd https://helm.linkerd.io/stable

# Update your local Helm chart repository cache
helm repo update

helm upgrade --install linkerd2 \
   linkerd/linkerd2 \
   --namespace linkerd \
   --set-file global.identityTrustAnchorsPEM=linkerd2/rootCA/ca.crt \
   --set identity.issuer.scheme=kubernetes.io/tls \
   --set installNamespace=false \
   --set proxyInjector.externalSecret=true \
   --set-file proxyInjector.caBundle=linkerd2/webhookCA/ca.crt \
   --set profileValidator.externalSecret=true \
   --set-file profileValidator.caBundle=linkerd2/webhookCA/ca.crt \
   --set tap.externalSecret=true \
   --set-file tap.caBundle=linkerd2/webhookCA/ca.crt \
   --set global.prometheusUrl='http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090' \
   --set prometheus.enabled=false \
   --version 2.9.2

```

# patch namespace to inject proxy

```
kubectl patch ns testing -p '{"metadata":{"annotations":{"linkerd.io/inject": "enabled"}}}'
```