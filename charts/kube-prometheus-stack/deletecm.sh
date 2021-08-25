for cm in $(kubectl get configmap -o name | grep linkerd)
do 
 echo "cm: $cm"
  kubectl delete  $cm
done