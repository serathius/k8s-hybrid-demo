#!/bin/bash -e
NODES=($(kubectl get nodes -l 'purpose notin (monitoring)' | tail -n +2 | grep ' Ready ' | cut -d' ' -f1))
INDEX=$(($RANDOM % ${#NODES[@]}))
NODE=${NODES[$INDEX]}
echo "Breaking communication to lb on node ${NODE}"
HAPROXY_POD_IP=$(kubectl get pods -l run=haproxy-ingress -o jsonpath='{.items[0].status.podIP}')
NGINX_POD_IP=$(kubectl get pods -l app=ingress-nginx -o jsonpath='{.items[0].status.podIP}')

gcloud compute ssh ${NODE} -- "while true; do sudo iptables --insert KUBE-FORWARD --source ${HAPROXY_POD_IP} --jump REJECT; sudo iptables --insert KUBE-FORWARD --source ${NGINX_POD_IP} --jump REJECT;sleep 1; done"
