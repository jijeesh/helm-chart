#!/bin/bash
echo "start" > out
while true
 do
  kubectl top pod --no-headers=true -l app.kubernetes.io/name=compute    | tee -a out
done
