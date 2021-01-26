# Request vs Limits

See the [following article](https://vincentlauzon.com/2019/04/02/requests-vs-limits-in-kubernetes/) for details.
kubectl run knife --image=jijeesh/knife --rm --restart=Never -it bash

curl "http://web-service/?duration=90"
curl "http://web-service/?duration=90&core=1"

http://jwt-validation-server.ingress-space.svc.cluster.local/validate

ab -n 1000 -c 1000 http://jwt-validation-server.ingress-space.svc.cluster.local/

curl -H 'Authorization: Token eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ik16YzBNVVV6UXpkRVJUZzRNekV5TnpFME1Ea3hPRGRCUlVSRlFUUkZNems1TlRrME9VUkJSQSJ9.eyJodHRwOi8vd3d3LmNhcC1mZWF0LmNvbS8iOltdLCJodHRwOi8vd3d3LmNhcC1lbWFpbC5jb20vIjoiY2FwdGVzdHVzZXIwMTFAZ21haWwuY29tIiwiaXNzIjoiaHR0cHM6Ly9leHRlbnNpb25zY2xvdWQuYXV0aDAuY29tLyIsInN1YiI6ImF1dGgwfDVlZmRlOWFhYWVkYjM3MDAxMzc5NGQ0ZSIsImF1ZCI6WyJodHRwczovL2xvZ2ljYWwtY2FwLWNvcmUuY29uZHVlbnQtY2FwLmNvbSIsImh0dHBzOi8vZXh0ZW5zaW9uc2Nsb3VkLmF1dGgwLmNvbS91c2VyaW5mbyJdLCJpYXQiOjE2MDc2MTkwODMsImV4cCI6MTYwNzcwNTQ4MywiYXpwIjoiQ3JWYUxuQUNZTHpTWUVkd1RIMEthdlNpSEhpU012N2IiLCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIGVtYWlsIGFkZHJlc3MgcGhvbmUiLCJndHkiOiJwYXNzd29yZCJ9.LrumnHtWXJN9uyra90gJuLCrnCgTj1nZn0mw6raH1B2rJOb9sWP7mXLBLkdKI5OBgdaoIXjrljbPkPWdfzBYKnu8eh6YlnLAzuT50RYmiDuWjBq3QgoyLaO4Sjikqxkmg_b7DVT6LSeI1VM0XCilJ0l4OWVoLlDbBHHeN__HG9aMtyrcVzocIa13S_f0ZQVFbaXVuo0N7E-P9G7HolzDi0AnWSki7PRa8lgdRtUsvuArWuLnv7U1uKJEUkWJMkOq6Q3kKWv4WhwOZYbf1jlGZZG4HyRKsscC1XRJKUO0inwcD9-xROpU2I5kpazKzzU6L__gBil2vBfWlUyt8qlHiQ' http://jwt-validation-server.ingress-space.svc.cluster.local/validate


ab -H 'Authorization: Token eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ik16YzBNVVV6UXpkRVJUZzRNekV5TnpFME1Ea3hPRGRCUlVSRlFUUkZNems1TlRrME9VUkJSQSJ9.eyJodHRwOi8vd3d3LmNhcC1mZWF0LmNvbS8iOltdLCJodHRwOi8vd3d3LmNhcC1lbWFpbC5jb20vIjoiY2FwdGVzdHVzZXIwMTFAZ21haWwuY29tIiwiaXNzIjoiaHR0cHM6Ly9leHRlbnNpb25zY2xvdWQuYXV0aDAuY29tLyIsInN1YiI6ImF1dGgwfDVlZmRlOWFhYWVkYjM3MDAxMzc5NGQ0ZSIsImF1ZCI6WyJodHRwczovL2xvZ2ljYWwtY2FwLWNvcmUuY29uZHVlbnQtY2FwLmNvbSIsImh0dHBzOi8vZXh0ZW5zaW9uc2Nsb3VkLmF1dGgwLmNvbS91c2VyaW5mbyJdLCJpYXQiOjE2MDc2MTkwODMsImV4cCI6MTYwNzcwNTQ4MywiYXpwIjoiQ3JWYUxuQUNZTHpTWUVkd1RIMEthdlNpSEhpU012N2IiLCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIGVtYWlsIGFkZHJlc3MgcGhvbmUiLCJndHkiOiJwYXNzd29yZCJ9.LrumnHtWXJN9uyra90gJuLCrnCgTj1nZn0mw6raH1B2rJOb9sWP7mXLBLkdKI5OBgdaoIXjrljbPkPWdfzBYKnu8eh6YlnLAzuT50RYmiDuWjBq3QgoyLaO4Sjikqxkmg_b7DVT6LSeI1VM0XCilJ0l4OWVoLlDbBHHeN__HG9aMtyrcVzocIa13S_f0ZQVFbaXVuo0N7E-P9G7HolzDi0AnWSki7PRa8lgdRtUsvuArWuLnv7U1uKJEUkWJMkOq6Q3kKWv4WhwOZYbf1jlGZZG4HyRKsscC1XRJKUO0inwcD9-xROpU2I5kpazKzzU6L__gBil2vBfWlUyt8qlHiQ' -n 1000 -c 1000 http://jwt-validation-server.ingress-space.svc.cluster.local/validate


ab -n 100 -c 10 http://web-service/
ab -n 50 -c 10 http://web-service/
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

curl --data "millicores=200&durationSec=200" compute:8080/ConsumeCPU
curl --data "millicores=300&durationSec=300" compute:8080/ConsumeCPU
curl --data "millicores=200&durationSec=1000" compute:8080/ConsumeCPU
curl --data "millicores=400&durationSec=300" compute:8080/ConsumeCPU
# curl --data "millicores=200&durationSec=200" compute:8080/ConsumeCPU
# curl --data "megabytes=400&durationSec=300" compute:8080/ConsumeMem

curl --data "megabytes=400&durationSec=300" compute:8080/ConsumeMem

rate(container_cpu_usage_seconds_total{ image!="", pod=~"compute-.*", container!="POD", container=~"compute-.*" }[5m])
# container usage
rate(container_cpu_usage_seconds_total{pod=~"compute-.*", image!="", container!="POD"}[5m])
sum (rate (container_cpu_usage_seconds_total{id="/"}[1m])) / sum (machine_cpu_cores) * 100
# container_spec_cpu_period
avg(container_spec_cpu_period{cluster="$cluster", namespace="$namespace", pod="$pod"})
# container_spec_cpu_quota
avg(container_spec_cpu_quota{cluster="$cluster", namespace="$namespace", pod="$pod"})
# container_spec_cpu_shares
avg(container_spec_cpu_shares{cluster="$cluster", namespace="$namespace", pod="$pod"})

rate(container_cpu_usage_seconds_total{namespace="$namespace",pod=~"$pod", container!="POD", image!="",container!="",cluster="$cluster"}[5m])
# container requests
avg(kube_pod_container_resource_requests_cpu_cores{pod=~"compute-.*"})

# container limits
avg(kube_pod_container_resource_limits_cpu_cores{pod=~"compute-.*"})

# throttling
rate(container_cpu_cfs_throttled_seconds_total{pod=~"compute-.*", container_name!="POD", image!=""}[5m])
container_cpu_cfs_periods_total
rate(container_cpu_cfs_periods_total{pod=~"compute-.*", container_name!="POD", image!=""}[5m])


rate(container_cpu_cfs_throttled_seconds_total{namespace="$namespace",pod=~"$pod", container_name!="POD", image!="",container!="",cluster="$cluster"}[5m])

rate(container_cpu_cfs_throttled_seconds_total{namespace="$namespace",pod=~"$pod", container_name!="POD", image!="",container!="",cluster="$cluster"}[5m]) * 1000



sum(increase(container_cpu_cfs_throttled_periods_total{namespace="$namespace", pod="$pod", container!="POD", container!="", cluster="$cluster"}[5m])) by (container) /sum(increase(container_cpu_cfs_periods_total{namespace="$namespace", pod="$pod", container!="POD", container!="", cluster="$cluster"}[5m])) by (container)