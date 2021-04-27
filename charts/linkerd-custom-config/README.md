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
openssl ecparam -genkey -name prime256v1

or

openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -x509 -subj "/CN=root.linkerd.cluster.local" -nodes -days 3650 -out rootCA/ca.crt -keyout rootCA/ca.key

kubectl create secret tls \
    linkerd-trust-anchor \
    --cert=certs/root.crt \
    --key=certs/root.key \
    --namespace=linkerd


```
# Create Certificate for Webhook 
```
step certificate create webhook.linkerd.cluster.local webhookCA/ca.crt webhookCA/ca.key \
  --profile root-ca --no-password --insecure --san webhook.linkerd.cluster.local

or
openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -x509 -subj "/CN=webhook.linkerd.cluster.local" -nodes -days 3650 -out webhookCA/ca.crt -keyout webhookCA/ca.key

kubectl create secret tls \
    webhook-issuer-tls \
    --cert=certs/webhook.crt \
    --key=certs/webhook.key \
    --namespace=linkerd
```
# split pem file
openssl pkey -in all.pem -out foo.key
openssl x509 -outform pem -in all.pem -out foo.crt

# check the validity

if openssl x509 -checkend $(( 24*3600*30 )) -noout -in ca.crt
then
  echo "Certificate is good for another day!"
else
  echo "Certificate has expired or will do so within 24 hours!"
  echo "(or is invalid/not found)"
fi

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
cat <<EOT > prometheus-values.yaml
prometheusSpec:
  retention: 15d
  retentionSize: 8GiB
  scrapeInterv: 30s
prometheus:
  prometheusSpec:
    podMonitorSelectorNilUsesHelmValues:  false
    serviceMonitorSelectorNilUsesHelmValues: false
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
# add prometheus datasource
```
tenant_id='$(et-cloud-tenant-id)'
domain_url='$(domain_url)'
grafana_app_secret='$(grafana_app_secret)'
grafana_app_id='$(grafana_app_id)'
grafana_url="https://grafana-$domain_url"
prometheus_stack_version="$(prometheus-stack_chart_version)"
grafana_auth_url="https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/authorize"
grafana_token_url="https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token"

cat <<EOT > grafana-values.yaml
grafana:
  sidecar:
    datasources:
      defaultDatasourceEnabled: false
  additionalDataSources:
    - name: prometheus
      type: prometheus
      url: http://prometheus-kube-prometheus-prometheus:9090/
      access: proxy
      isDefault: true
  admin:
    existingSecret: prometheus-grafana-secret
    passwordKey: admin-password
    userKey: admin-user
  grafana.ini:
    analytics:
      check_for_updates: true
    auth.azuread:
      allow_sign_up: true
      allowed_groups: $(grafana_allowed_groups)
      auth_url: $grafana_auth_url
      client_id: $grafana_app_id
      client_secret: $grafana_app_secret
      enabled: true
      name: Azure AD
      scopes: openid email profile
      token_url: $grafana_token_url
    grafana_net:
      url: https://grafana.net    
    server:
      root_url: $grafana_url
  deploymentStrategy:
    type: Recreate
  persistence:
    accessModes:
    - ReadWriteOnce
    enabled: true
    finalizers:
    - kubernetes.io/pvc-protection
    size: 5Gi
    storageClass: managed-premium
    type: pvc
EOT
```

# Install custom linkerd configuration

This will install in two namespaces , monitoring and linkerd
```
helm upgrade --install linkerd-custom-config -n linkerd
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
kubectl patch ns enterprise-services -p '{"metadata":{"annotations":{"linkerd.io/inject": "enabled"}}}'

kubectl patch ns apps -p '{"metadata":{"annotations":{"linkerd.io/inject": "enabled"}}}'

```

# Rotating the trust anchor
https://linkerd.io/2/tasks/manually-rotating-control-plane-tls-credentials/

Generate a new trust anchor
Deploying the new bundle to Linkerd

This will restart the proxies in the Linkerd control plane, and they will be reconfigured with the new trust anchor.

Finally, you must restart the proxy for all injected workloads in your cluster. For example, doing that for the emojivoto namespace would look like:
```
kubectl -n emojivoto rollout restart deploy
```

# Rotating the identity issuer certificate
At this point Linkerd's upgrade, identity control plane service should detect the change of the secret and automatically update its issuer certificates.

Restart the proxy for all injected workloads in your cluster to ensure that their proxies pick up certificates issued by the new issuer:

```
kubectl -n emojivoto rollout restart deploy
```

# trouble shooting

check injector certificate

```
openssl s_client -showcerts -connect linkerd-proxy-injector.linkerd.svc:443
```

```
curl --insecure -vvI https://linkerd-proxy-injector.linkerd.svc:443 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'

curl --insecure -vvI https://linkerd-sp-validator.linkerd.svc:443 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'

curl --insecure -vvI https://linkerd-tap.linkerd.svc:443 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'

curl --insecure -vvI https://linkerd-identity.linkerd.svc:8080 2>&1 | awk 'BEGIN { cert=0 } /^\* Server certificate:/ { cert=1 } /^\*/ { if (cert) print }'
```
# autoscale with keda
#script.js
```
import http from 'k6/http';
import { sleep } from 'k6';

export default function () {
  http.get('http://nginx');
  sleep(1);
}
```
```
cat <<EOT > script.js
import http from 'k6/http';
import { sleep } from 'k6';

export default function () {
  http.get('http://nginx');
  sleep(1);
}
EOT

```
````
k6 run --vus 12 --duration 60s script.js

````