
https://betterprogramming.pub/k8s-tips-using-a-serviceaccount-801c433d0023

https://www.ibm.com/docs/en/cloud-paks/cp-management/2.0.0?topic=kubectl-using-service-account-tokens-connect-api-server

https://itnext.io/helm-3-mapping-a-directory-of-files-into-a-container-ed6c54372df8


TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl --cacert ca.crt -H "Authorization: Bearer ${TOKEN}" https://kubernetes.default.svc.cluster.local/api/v1 --insecure 


kubectl config set-cluster cfc --server=https://kubernetes.default.svc.cluster.local --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
kubectl config set-context cfc --cluster=cfc
kubectl config set-credentials user --token=${TOKEN}
kubectl config set-context cfc --user=user
kubectl config use-context cfc