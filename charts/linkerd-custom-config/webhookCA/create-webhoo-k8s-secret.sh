kubectl create secret tls \
    webhook-issuer-tls \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd