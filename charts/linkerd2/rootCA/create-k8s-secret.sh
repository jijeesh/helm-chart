kubectl create secret tls \
    linkerd-trust-anchor \
    --cert=ca.crt \
    --key=ca.key \
    --namespace=linkerd