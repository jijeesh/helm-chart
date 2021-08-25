#!/bin/bash
linkerd_certificate_change=false
linkerd_proxy_enabled_ns=#{linkerd_proxy_enabled_ns}#
linkerd_verstion=#{linkerd_verstion}#
linkerd_lifetime_action_in_days=#{linkerd_lifetime_action_in_days}#
linkerd_reset="#{linkerd_reset}#"
prometheus_internal_url='#{prometheus_internal_url}#'
linkerd_ha_enabled="#{linkerd_ha_enabled}#"
linkerd_production_enabled="#{linkerd_production_enabled}#"
linkerd_extensions_enabled="#{linkerd_extensions_enabled}#" # core,viz,jaeger


if [ -f ./env ]
then
source ./env
fi

print_var(){
echo "linkerd_proxy_enabled_ns=$linkerd_proxy_enabled_ns"
echo "linkerd_verstion=$linkerd_verstion"
echo "linkerd_lifetime_action_in_days=$linkerd_lifetime_action_in_days"
echo "linkerd_reset=$linkerd_reset"
echo "prometheus_internal_url=$prometheus_internal_url"
echo "linkerd_ha_enabled=$linkerd_ha_enabled"
echo "linkerd_production_enabled=$linkerd_production_enabled"
}
print_var

# Declare an array of linkerd namespaces
# declare -a linkerd_ns=("linkerd","linkerd-viz","linkerd-jaeger")
declare -a linkerd_ns=("linkerd")
# Declare an array of certificate list
# declare -a certificateList=("root" "webhook")
declare -a certificateList=("linkerd-trust-anchor" "webhook-issuer-tls")
declare -a secretNames=("linkerd-identity-issuer" "linkerd-proxy-injector-k8s-tls" "linkerd-sp-validator-k8s-tls")
declare -a secretNames_viz=("tap-k8s-tls" "tap-injector-k8s-tls")
declare -a secretNames_jaeger=("jaeger-injector-k8s-tls")

delete_secrets(){
   local ns=$1
   shift
   local secretNames=("$@")
   
echo "*************delete_secrets*******************"
for secretName in ${secretNames[@]}; do
echo "Delete secretName: $secretName from namespace $ns"
kubectl -n $ns delete secrets $secretName

done
}


create_certificate(){
    echo "*************create_certificate*******************"
    cert_name=$1
#     step certificate create ${cert_name}.linkerd.cluster.local certs/${cert_name}.crt certs/${cert_name}.key \
#   --profile root-ca --no-password --insecure --san ${cert_name}.linkerd.cluster.local

openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
 -x509 -subj "/CN=${cert_name}.linkerd.cluster.local" \
  -nodes -days 3650 -out certs/$cert_name.crt -keyout certs/$cert_name.key 
}

download_certificate(){
    echo "*************download_certificate*******************"
    cert_name=$1
    local ca_secrets=$(kubectl -n linkerd get secret "${cert_name}" -ojson | jq -j '.data')

    echo $ca_secrets  | jq -j '."tls.crt"' | base64 --decode > certs/${cert_name}.crt
    echo $ca_secrets  | jq -j '."tls.key"' | base64 --decode > certs/${cert_name}.key
}

validate_certificate(){
    echo "*************validate_certificate*******************"
    cert_name=$1
    if openssl x509 -checkend $(( 24*3600*${linkerd_lifetime_action_in_days} )) -noout -in certs/$cert_name.crt
    then
    echo "Certificate $cert_name is good for another day!"
    else
    echo "Certificate $cert_name has expired or will do so within $linkerd_lifetime_action_in_days hours!"
    echo "(or is invalid/not found)"
    create_certificate $cert_name
    linkerd_certificate_change=true
    fi
}

kubectl_patch(){
    echo "*************kubectl_patch*******************"
    for namespace in $(echo $linkerd_proxy_enabled_ns | sed "s/,/ /g")
    do
        if [[ ! "${linkerd_ns[@]}" =~ "${namespace}" ]]
        then
        echo "Injecting linkerd proxy into the namespace: $namespace"
        kubectl patch ns $namespace -p '{"metadata":{"annotations":{"linkerd.io/inject": "enabled"}}}'
        fi
    done
}

rollout_status(){
    echo "*************rollout_status*******************"
    echo "Check the Rollout status in namespace $1"
    namespace=$1
    deploy=$(kubectl -n $1 get $2 -o name)
    for i in $deploy
            do
                if [ $namespace == "linkerd" ]
                then
                    echo "Rollout stats of $i"
                    kubectl -n $namespace rollout status $i -w --timeout=600s
                    if [[ "$?" -ne 0 ]] 
                    then
                        line="Rollout status failed!"
                        echo -e "\e[01;31m$line\e[0m"
                        exit 1
                    else
                        echo "Rollout succeeded"
                    fi
                elif [ $2 == "sts" ]
                then
                    echo "Rollout stats of $i"
                    kubectl -n $namespace rollout status $i -w --timeout=600s
                    if [[ "$?" -ne 0 ]] 
                    then
                        line="Rollout status failed!"
                        echo -e "\e[01;31m$line\e[0m"
                        # exit 1
                    else
                        echo "Rollout succeeded"
                    fi

                else
                    echo "Rollout stats of $i"
                    # kubectl -n $namespace rollout status $i -w --timeout=1s
                fi
                
            done
}
restart_pods(){
    echo "*************restart_pods*******************"
    echo "Restart  $2 inside the namespace $1"
    kubectl -n $1 rollout restart $2
    rollout_status $1 $2

}

restart_deployment(){
    echo "*************restart_deployment*******************"
# delete_secrets
sleep 5s
for namespace in $(echo $linkerd_proxy_enabled_ns | sed "s/,/ /g")
do
    
        echo " Restart depoyments $namespace"
        restart_pods  $namespace "sts"
        restart_pods  $namespace deploy
          
done
    
}

func_exit(){
if [ $? -ne 0 ]; then
    echo "Error: Return code was not zero"
    exit 0
fi
}

deploy(){
    echo "*************deploy*******************"
    # deploy custom config
echo "Upgrading linkerd-custom-config"
helm upgrade --install --namespace linkerd \
--set certificateChange=${linkerd_certificate_change} \
--set linkerdReset=${linkerd_reset} \
linkerd-custom-config .



current_app_version=$(helm history linkerd2 -n linkerd --max=1 -o json | jq -r '.[].app_version')
echo "current_app_version: $current_app_version"

if [ "$current_app_version" == "stable-${linkerd_verstion}" ]
then
 echo "Same App Version is installing"
 atomic='--atomic'
else
 echo "Different app Version installing.  Current_app_version is $current_app_version  and installing stable-${linkerd_verstion}"
 
 atomic='--reset-values  --atomic'
fi

# To add the repo for Linkerd2 stable releases:
helm repo add linkerd https://helm.linkerd.io/stable
# Update your local Helm chart repository cache
helm repo update
helm pull linkerd/linkerd2 --version $linkerd_verstion --untar
helm pull linkerd/linkerd-viz --version $linkerd_verstion --untar
helm pull linkerd/linkerd-jaeger --version $linkerd_verstion --untar

if [ "$linkerd_production_enabled" == "true" ]
then
    echo "Production enabled"
    values_file='-f linkerd2/values.yaml -f linkerd2/values-ha.yaml'
    values_file_viz='-f linkerd-viz/values.yaml -f linkerd-viz/values-ha.yaml'
    values_file_jaeger='-f linkerd-jaeger/values.yaml'
elif [ "$linkerd_ha_enabled" == "true" ]
then
    echo "HA enabled"
    values_file='--set enablePodAntiAffinity=false -f linkerd2/values.yaml -f linkerd2/values-ha.yaml'
    values_file_viz='--set enablePodAntiAffinity=false -f linkerd-viz/values.yaml -f linkerd-viz/values-ha.yaml'
    values_file_jaeger='-f linkerd-jaeger/values.yaml'
else
    echo "HA Disabled"
    values_file='-f linkerd2/values.yaml'
    values_file_viz='-f linkerd-viz/values.yaml'
    values_file_jaeger='-f linkerd-jaeger/values.yaml'
fi
# Post-upgrade cleanup
delete_secrets "linkerd" "${secretNames[@]}"

delete_secrets "linkerd-viz" "${secretNames_viz[@]}"

delete_secrets "linkerd-jaeger" "${secretNames_jaeger[@]}"

if [[ $linkerd_extensions_enabled =~ (^|,)"core"(,|$) ]]; then
echo "Upgrading linkerd"
helm upgrade --install linkerd2 \
   linkerd2 \
   --namespace linkerd \
   --set-file identityTrustAnchorsPEM=certs/linkerd-trust-anchor.crt \
   --set identity.issuer.scheme=kubernetes.io/tls \
   --set installNamespace=false \
   --set proxyInjector.externalSecret=true \
   --set-file proxyInjector.caBundle=certs/webhook-issuer-tls.crt \
   --set profileValidator.externalSecret=true \
   --set-file profileValidator.caBundle=certs/webhook-issuer-tls.crt \
   --version $linkerd_verstion \
   --timeout 10m0s \
   $values_file $atomic

# exit if any error
func_exit
fi


if [[ $linkerd_extensions_enabled =~ (^|,)"viz"(,|$) ]]; then
# ignore if not using the viz extension
echo "Upgrading linkerd-viz"
helm upgrade --install linkerd-viz \
   linkerd-viz \
   --namespace linkerd-viz \
   --set installNamespace=false \
   --set tap.externalSecret=true \
   --set-file tap.caBundle=certs/webhook-issuer-tls.crt \
   --set tapInjector.externalSecret=true \
   --set-file tapInjector.caBundle=certs/webhook-issuer-tls.crt \
   --set prometheusUrl=$prometheus_internal_url \
   --set prometheus.enabled=false \
   --version $linkerd_verstion \
   --timeout 10m0s \
   $values_file_viz  $atomic

# exit if any error
func_exit
fi


if [[ $linkerd_extensions_enabled =~ (^|,)"abc"(,|$) ]]; then
# ignore if not using the jaeger extension
echo "Upgrading linkerd-jaeger"
helm upgrade --install linkerd-jaeger \
 linkerd-jaeger \
 --namespace linkerd-jaeger \
 --set installNamespace=false \
 --set webhook.externalSecret=true \
 --set-file webhook.caBundle=certs/webhook-issuer-tls.crt \
 --version $linkerd_verstion \
 --timeout 10m0s \
 $values_file_jaeger $atomic

# exit if any error
func_exit
fi


# linkerd install --config=config.yml | kubectl apply -f -

# # ignore if not using the viz extension
# linkerd viz install --config=config-viz.yml | kubectl apply -f -

# # ignore if not using the jaeger extension
# linkerd jaeger install --config=config-jaeger.yml | kubectl apply -f -

}


create_namespace(){
    local ns=$1
    echo "*************create_namespace $ns*******************"
    # Create a dedicated namespace where you would like to deploy linkerd into
    if [ "`kubectl get ns ${ns} -o name`" != "namespace/${ns}" ]; then
            echo "Namespace ${ns} doesnt exists, creating"       
            kubectl create namespace ${ns}
    else
        echo "Namespace ${ns} already exists"
    fi
    
}
# create namespaces if it not exists

   create_namespace 'linkerd'


   create_namespace 'linkerd-viz'
   kubectl patch ns linkerd-viz -p '{"metadata": {"annotations": {"linkerd.io/inject": "enabled"},"labels": {"linkerd.io/extension": "viz" }}}'



   create_namespace 'linkerd-jaeger'
   kubectl patch ns linkerd-jaeger -p '{"metadata": {"annotations": {"linkerd.io/inject": "enabled"},"labels": {"linkerd.io/extension": "jaeger" }}}'




# add a patch into the ns
kubectl_patch

# Iterate the string array using for loop
certificate_file_count=0
CERT_DIRECTORY=certs
if [ -d "$CERT_DIRECTORY" ]; then
    echo "Directory already exsits"
   rm -rf ${CERT_DIRECTORY}
fi
echo "creating directory"
mkdir -p ${CERT_DIRECTORY}

if [ "$linkerd_reset" == "true" ]
    then
        echo "Reset enabled"
        echo "Uninstall linkerd custom config"
        helm un linkerd-custom-config --namespace linkerd
        echo "Uninstall linkerd2"
        helm un linkerd2 --namespace linkerd
        echo "Uninstall linkerd-viz"
        helm un linkerd-viz --namespace linkerd-viz
        echo "Uninstall linkerd-jaeger"
        helm un linkerd-jaeger --namespace linkerd-jaeger
fi

for certificate in ${certificateList[@]}; do
    if [ "$linkerd_reset" != "true" ]
    then        
        echo "Download certificate for $certificate"
        download_certificate $certificate
    fi
   echo "Validate certificate for $certificate"
   validate_certificate $certificate
   if [ -f certs/${certificate}.crt ] 
    then
        
        certificate_file_count=$((certificate_file_count+1))
        echo "Certificate File  found! $certificate_file_count"
    fi
done

if [ $certificate_file_count == 2 ]
then
    echo "Deploy Linkerd"
    deploy
else    
    line="Could not found valid certificate"
    echo -e "\e[01;31m$line\e[0m"
    exit
fi

if [ "$linkerd_certificate_change" == "true" ]
    then
        echo "New Certificate Generated"
        restart_deployment

    else
        echo "Certificate is good"
fi


