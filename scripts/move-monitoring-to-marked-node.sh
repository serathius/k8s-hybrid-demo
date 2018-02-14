#!/bin/bash -e

function patch {
  TYPE=$1
  NAME=$2
  JSON_PATH=$3
  VALUE=$4
  PATCH=$5
  if [ "$(kubectl -n monitoring get ${TYPE} ${NAME} -o jsonpath=${JSON_PATH})" != "${VALUE}" ] ; then
    kubectl -n monitoring patch ${TYPE} ${NAME} --patch "$PATCH" --type=merge
  fi
}
patch prometheus k8s '{.spec.nodeSelector.purpose}' 'monitoring' '{"spec":{"nodeSelector":{"purpose":"monitoring"}}}'
patch alertmanager main '{.spec.nodeSelector.purpose}' 'monitoring' '{"spec":{"nodeSelector":{"purpose":"monitoring"}}}'
patch deployment prometheus-operator '{.spec.template.spec.nodeSelector.purpose}' 'monitoring' '{"spec":{"template":{"spec":{"nodeSelector":{"purpose":"monitoring"}}}}}'
patch deployment grafana '{.spec.template.spec.nodeSelector.purpose}' 'monitoring' '{"spec":{"template":{"spec":{"nodeSelector":{"purpose":"monitoring"}}}}}'
patch deployment kube-state-metrics '{.spec.template.spec.nodeSelector.purpose}' 'monitoring' '{"spec":{"template":{"spec":{"nodeSelector":{"purpose":"monitoring"}}}}}'
