#!/bin/bash -e

: ${PROMETHEUS_URL?"Need to set PROMETHEUS_URL"}
: ${GRAFANA_FILE?"Need to set GRAFANA_FILE"}

cat > ${GRAFANA_FILE} << EOF
server:
  setDatasource:
    enabled: true
    datasource:
      name: prometheus
      type: prometheus
      url: ${PROMETHEUS_URL}
dashboardImports:
  enabled: true
  files:
EOF
for file in grafana/*.json ; do
  VARIABLES=$(cat ${file} | jq -r '[.__inputs[] | "${\(.name)}"] | join(" ")')
  export $(cat ${file} | jq -r '.__inputs[] | [.name, (if .value? then .value else .pluginId end)] | join("=")')
  cat >> ${GRAFANA_FILE} << EOF
    ${file##*/}: '$(cat ${file} | jq . -c | envsubst "${VARIABLES}")'
EOF
done

