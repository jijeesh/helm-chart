#!/bin/bash
for secret in "linkerd-trust-anchor"; do \
  kubectl -n linkerd get secret "${secret}" -ojson | jq -j '.data."tls.crt"' | \
    base64 --decode - | \
    step certificate inspect - | \
    grep -iA2 validity; \
done