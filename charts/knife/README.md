
https://betterprogramming.pub/k8s-tips-using-a-serviceaccount-801c433d0023
https://www.ibm.com/docs/en/cloud-paks/cp-management/2.0.0?topic=kubectl-using-service-account-tokens-connect-api-server


TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl --cacert ca.crt -H "Authorization: Bearer ${TOKEN}" https://kubernetes.default.svc.cluster.local/api/v1 --insecure 

curl --cacert ca.crt -H "Authorization: Bearer ${TOKEN}" https://${KUBERNETES_ERVICE_HOST}/api/v1 --insecure


curl --cacert ca.crt  -H “Authorization: Bearer $TOKEN” https://kubernetes.default.svc.cluster.local/api/v1/namespaces/testing/pods/ --insecure

curl --cacert ca.crt  -H “Authorization: Bearer $TOKEN” https://kubernetes.default.svc.cluster.local/api/v1/pod/namespaces/testing --insecure

curl --cacert ca.crt  -H “Authorization: Bearer $TOKEN” https://10.0.0.1/api/v1/namespaces/testing/pods/ --insecure


kubectl config set-cluster cfc --server=https://kubernetes.default.svc.cluster.local --certificate-authority=ca.crt
kubectl config set-context cfc --cluster=cfc
kubectl config set-credentials user --token=${TOKEN}
kubectl config set-context cfc --user=user
kubectl config use-context cfc