include defaults.env
export $(shell sed 's/=.*//' defaults.env)

all: move-monitoring-to-marked-node manifests dashboards

manifests: tls-secret
	kubectl apply -f manifests --recursive
	envsubst < manifests/load/load-deployment.yml.tmpl | kubectl apply -f -

move-monitoring-to-marked-node: mark-node
	./scripts/move-monitoring-to-marked-node.sh

mark-node:
	./scripts/mark-node.sh

hook-overload-frontend:
	LOAD_USER_COUNT=100 LOAD_REPLICAS=4 envsubst < manifests/load/load-deployment.yml.tmpl | kubectl apply -f -

hook-overload-frontend-revert:
	envsubst < manifests/load/load-deployment.yml.tmpl | kubectl apply -f -

hook-break-connection-from-node-to-master:
	./scripts/break-conn-node-master.sh
	printf "Revert using\nmake hook-break-connection-from-node-to-master-revert"

hook-break-connection-from-node-to-master-revert:
	./scripts/break-conn-node-master.sh REVERT

hook-break-connection-from-node-to-lb:
	./scripts/break-conn-node-lb.sh

hook-delete-pod-application:
	LABEL_SELECTOR='app=guestbook' ./scripts/delete-pod.sh

hook-delete-pod-redis-slave:
	LABEL_SELECTOR='app=redis,role=slave' ./scripts/delete-pod.sh

hook-delete-pod-redis-master:
	LABEL_SELECTOR='app=redis,role=master' ./scripts/delete-pod.sh

hook-delete-node:
	./scripts/delete-node.sh

hook-clear-redis-records:
	kubectl exec -it $$(kubectl get pods | grep redis-master | cut -f1 -d' ') -c redis-master -- redis-cli FLUSHALL

clean:
	kubectl delete -f manifests --recursive
	rm build

tls-secret: build/tls.crt build/tls.key
	kubectl create secret tls tls-secret --cert=build/tls.crt --key=build/tls.key || true

build/tls.crt build/tls.key: build
	openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout build/tls.key -out build/tls.crt -subj '/CN=localhost'

build:
	mkdir -p build

dashboards := $(wildcard grafana/*-dashboard.json)
dashboard_targets := $(patsubst grafana/%,build/dashboards/%,$(dashboards))
datasources := $(wildcard grafana/*-datasource.json)
datasource_targets := $(patsubst grafana/%,build/dashboards/%,$(datasources))

build/dashboards:
	mkdir -p build/dashboards

build/dashboards/%-dashboard.json: build/dashboards grafana/%-dashboard.json
	cat grafana/$*-dashboard.json | jq -c '{dashboard:., overwrite: true, inputs: [.__inputs[] | {name:.name, type:.type, value: (if .value? then .value else .pluginId end), pluginId:.pluginId}| delpaths([path(.[]| select(.==null))])] }' > build/dashboards/$*-dashboard.json

build/dashboards/%-datasource.json: build/dashboards grafana/%-datasource.json
	cp grafana/$*-datasource.json build/dashboards

build/grafana-configmap.yml: $(datasource_targets) $(dashboard_targets)
	kubectl -n monitoring create configmap grafana-dashboards-0 --from-file=build/dashboards/ --dry-run -o yaml > build/grafana-configmap.yml

dashboards: build/grafana-configmap.yml
	kubectl apply -f build/grafana-configmap.yml

.PHONY: deploy clean tls-secret dashboards
