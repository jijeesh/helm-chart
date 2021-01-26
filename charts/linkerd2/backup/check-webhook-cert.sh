#!/bin/bash
for secret in "linkerd-proxy-injector-k8s-tls" "linkerd-sp-validator-k8s-tls" "linkerd-tap-k8s-tls"; do \
  echo "Secret: $secret"
  kubectl -n linkerd get secret "${secret}" -ojson | jq -j '.data."tls.crt"' | \
    base64 --decode - | \
    step certificate inspect - | \
    grep -iA2 validity; \
done