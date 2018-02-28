#!/bin/bash -e
NODES=($(kubectl get nodes -l 'purpose notin (monitoring)' | tail -n +2 | grep ' Ready ' | cut -d' ' -f1))
INDEX=$(($RANDOM % ${#NODES[@]}))
NODE=${NODES[$INDEX]}
echo "Breaking communication to lb on node ${NODE}"
LB_POD_IP=$(kubectl get pods -l run=haproxy-ingress -o jsonpath='{.items[0].status.podIP}')

gcloud compute ssh ${NODE} -- "while true; do sudo iptables --insert KUBE-FORWARD --source ${LB_POD_IP} --jump REJECT; sleep 1; done"
