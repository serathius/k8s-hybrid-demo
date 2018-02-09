#!/bin/bash -e

if ! [[ $(kubectl get nodes -l 'purpose=monitoring' -o jsonpath='{.items[*].metadata.name}') ]] ; then
  NODES=($(kubectl get nodes -l 'purpose notin (monitoring)' -o jsonpath='{.items[*].metadata.name}'))
  INDEX=$(($RANDOM % ${#NODES[@]}))
  NODE_TO_TAG=${NODES[$INDEX]}
  kubectl label node ${NODE_TO_TAG} 'purpose=monitoring'
fi
