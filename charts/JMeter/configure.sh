#!/bin/bash
releasename=jmeter
master_pod=$(kubectl get pods | grep ${releasename}-master | awk '{print $1}')
echo "master_pod: $master_pod"
COUNTER=1
grafana_pod=$(kubectl get pods |grep grafana |awk '{print $3}')
echo "grafana_pod : $grafana_pod"
while [[ "$grafana_pod" != "Running" ]]
do
echo "INFO: Checking grafana pod is running ...check#"$COUNTER
let COUNTER++
sleep 5
done

echo "INFO: Adding default dashboard"
kubectl cp ./install/jmeter/files/jmeterdash.json $master_pod:/jmeterdash.json
jmeter_grafana_password=$(jmeter_grafana_password)
kubectl exec -ti $master_pod -- curl "http://admin:${jmeter_grafana_password}@jmeter-grafana/api/dashboards/db" -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '@jmeterdash.json'

echo "INFO: Default dashboard has been added"