#!/bin/bash
for secret in "linkerd-identity-issuer"; do \
  kubectl -n linkerd get secret "${secret}" -ojson | jq -j '.data."crt.pem"' | \
    base64 --decode - | \
    step certificate inspect - | \
    grep -iA2 validity; \
done