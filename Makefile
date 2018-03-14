include defaults.env
export $(shell sed 's/=.*//' defaults.env)

helm_prometheus_name := logmon-prom
helm_grafana_name := logmon-graf

all: prometheus grafana manifests

tiller:
	helm init
	kubectl create serviceaccount --namespace kube-system tiller
	kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'ometheus:

prometheus:
	helm install stable/prometheus --name $(helm_prometheus_name) --version 5.4.2

grafana: build/grafana.yml
	helm install stable/grafana --name $(helm_grafana_name) --values build/grafana.yml --version 0.8.2

manifests: tls-secret
	kubectl apply -f manifests --recursive
	envsubst < manifests/load/load-deployment.yml.tmpl | kubectl apply -f -

grafana-password:
	kubectl get secret --namespace default $(helm_grafana_name)-grafana -o jsonpath="{.data.grafana-admin-password}" | base64 --decode; echo

grafana-forward:
	kubectl --namespace default port-forward $$(kubectl get pods --namespace default -l "app=$(helm_grafana_name)-grafana,component=grafana" -o jsonpath="{.items[0].metadata.name}") 3000

build/grafana.yml: build
	GRAFANA_FILE=build/grafana.yml PROMETHEUS_URL=http://$(helm_prometheus_name)-prometheus-server ./scripts/template-helm.sh

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
	-kubectl delete -f manifests --recursive &> /dev/null
	-helm del --purge $(helm_prometheus_name)
	-helm del --purge $(helm_grafana_name)
	-rm build -rf

tls-secret: build/tls.crt build/tls.key
	kubectl create secret tls tls-secret --cert=build/tls.crt --key=build/tls.key || true

build/tls.crt build/tls.key: build
	openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout build/tls.key -out build/tls.crt -subj '/CN=localhost'

build:
	mkdir -p build

.PHONY: deploy clean tls-secret prometheus grafana helm
