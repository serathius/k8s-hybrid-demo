#!/bin/bash -e
NODE_HOST=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="Hostname")].address}' | cut -f1 -d' ')
MASTER_ENDPOINT=$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}')
if [ "$1" == "REVERT" ]; then
  echo "Reverting breaking node: ${NODE_HOST}"
  gcloud compute ssh ${NODE_HOST} -- "while \$(sudo iptables --delete OUTPUT --destination ${MASTER_ENDPOINT} --jump REJECT); do :; done"
  EXPECTED_READY_STATE="True"
else
  echo "Fixing node: ${NODE_HOST}"
  gcloud compute ssh ${NODE_HOST} -- sudo iptables --insert OUTPUT --destination ${MASTER_ENDPOINT} --jump REJECT
  EXPECTED_READY_STATE="Unknown"
fi
NODE_CURRENT_READY_STATE=$(kubectl get node ${NODE_HOST} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
while [ ${NODE_CURRENT_READY_STATE} != ${EXPECTED_READY_STATE} ] ; do
  echo "Waiting for node state READY=${EXPECTED_READY_STATE}, current state READY=${NODE_CURRENT_READY_STATE}"
  sleep 3
  NODE_CURRENT_READY_STATE=$(kubectl get node ${NODE_HOST} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
done;
echo "Node status: ${NODE_CURRENT_READY_STATE}"
