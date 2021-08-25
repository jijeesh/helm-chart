# Request vs Limits

See the [following article](https://vincentlauzon.com/2019/04/02/requests-vs-limits-in-kubernetes/) for details.
kubectl run knife --image=jijeesh/knife --rm --restart=Never -it bash

curl "http://web-service/?duration=90"
curl "http://web-service/?duration=90&core=1"

http://jwt-validation-server.ingress-space.svc.cluster.local/validate

ab -n 1000 -c 1000 http://jwt-validation-server.ingress-space.svc.cluster.local/

curl -H 'Authorization: Token dddddddddddddddddddddddd' http://jwt-validation-server.ingress-space.svc.cluster.local/validate


ab -H 'Authorization: Token aaaaaaaaaaaaaaaaaaaaaaaa' -n 1000 -c 1000 http://jwt-validation-server.ingress-space.svc.cluster.local/validate


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

```
cat <<EOT > compute.js
import http from 'k6/http';
import { sleep } from 'k6';
const url = 'http://compute:8080/ConsumeCPU';
export default function () {
  let data = 'millicores=200&durationSec=200'
  http.post(url, data);
  sleep(1);
}
EOT

```
````
k6 run --vus 12 --duration 60s compute.js

````





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