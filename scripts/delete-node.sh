#!/bin/bash -e
NODES=($(kubectl get nodes -l 'purpose notin (monitoring)' -o jsonpath='{.items[*].metadata.name}'))
INDEX=$(($RANDOM % ${#NODES[@]}))
NODE_TO_DELETE=${NODES[$INDEX]}
gcloud compute instances delete ${NODE_TO_DELETE}
