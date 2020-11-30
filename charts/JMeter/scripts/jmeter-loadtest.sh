#!/bin/bash

namespace=tools
deployment=jmeter-slaves
timeout=60s

loadresults='loadresults'
maxReplicas=${max_replicas:-#{max_replicas}#}
minReplicas=${min_replicas:-#{min_replicas}#}
jmx=${jmx_file:-#{jmx_file}#}




scale(){

    readyReplicas=$1
    replicas=$2
    kubectl --namespace $namespace scale deploy ${deployment}  --replicas=$replicas
    until [ "$replicas" == "$readyReplicas" ]
    do
    readyReplicas=$(kubectl get deployment --namespace $namespace ${deployment}  -o json | jq '.status.readyReplicas' )
    if [ "$readyReplicas" == 'null' ]
        then
        readyReplicas=0
    fi
    sleep 5
    echo "readyReplicas : $readyReplicas"
    done
}
jtl_junit_converter(){
    test_name=$1
    
    python3 jtl_junit_converter.py $loadresults/$test_name.jtl $loadresults/$test_name.xml
}


load_test(){
working_dir="`pwd`"

#Get namesapce variable

# jmx=$1
[ -n "$jmx" ] || read -p 'Enter path to the jmx file ' jmx

if [ ! -f "$jmx" ];
then
    echo "Test script file was not found in PATH"
    echo "Kindly check and input the correct file path"
    exit
fi

test_file="$(basename "$jmx")"
test_name="${test_file%.*}"
echo "test file name: $test_name"
#Get Master pod details

master_pod=`kubectl --namespace $namespace get po  | grep jmeter-master | awk '{print $1}'`

kubectl --namespace $namespace cp "$jmx"  "$master_pod:/$test_name.jmx"

## Echo Starting Jmeter load test

kubectl --namespace $namespace exec -ti $master_pod -- /bin/bash /load_test "$test_name" 
sleep 10s
mkdir -p $loadresults
kubectl --namespace $namespace cp $master_pod:/$test_name.jtl $loadresults/$test_name.jtl


jtl_junit_converter $test_name


}


scale $maxReplicas $minReplicas
scale $minReplicas $maxReplicas
load_test 
scale $maxReplicas $minReplicas