#!/bin/bash -e
if [ "$1" == "REVERT" ]; then
  NODES=($(kubectl get nodes -l "purpose notin (monitoring)" | grep -v ' Ready ' | cut -d' ' -f1))
else
  NODES=($(kubectl get nodes -l 'purpose notin (monitoring)' | tail -n +2 | grep ' Ready ' | cut -d' ' -f1))
fi

INDEX=$(($RANDOM % ${#NODES[@]}))
NODE=${NODES[$INDEX]}

MASTER_ENDPOINT=$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}')
if [ "$1" == "REVERT" ]; then
  echo "Reverting breaking node: ${NODE}"
  gcloud compute ssh ${NODE} -- "while \$(sudo iptables --delete OUTPUT --destination ${MASTER_ENDPOINT} --jump REJECT); do :; done"
  EXPECTED_READY_STATE="True"
else
  echo "Breaking node: ${NODE}"
  gcloud compute ssh ${NODE} -- sudo iptables --insert OUTPUT --destination ${MASTER_ENDPOINT} --jump REJECT
  EXPECTED_READY_STATE="Unknown"
fi
NODE_CURRENT_READY_STATE=$(kubectl get node ${NODE} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
while [ ${NODE_CURRENT_READY_STATE} != ${EXPECTED_READY_STATE} ] ; do
  echo "Waiting for node state READY=${EXPECTED_READY_STATE}, current state READY=${NODE_CURRENT_READY_STATE}"
  sleep 3
  NODE_CURRENT_READY_STATE=$(kubectl get node ${NODE} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
done;
echo "Node status: ${NODE_CURRENT_READY_STATE}"
