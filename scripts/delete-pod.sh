#!/bin/bash -e
: ${LABEL_SELECTOR?"Need to set LABEL_SELECTOR"}

PODS=($(kubectl get pods -l ${LABEL_SELECTOR} -o jsonpath='{.items[*].metadata.name}'))
INDEX=$(($RANDOM % ${#PODS[@]}))
POD_TO_DELETE=${PODS[$INDEX]}
kubectl delete pod ${POD_TO_DELETE} --force=true
