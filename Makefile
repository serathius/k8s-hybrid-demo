include defaults.env
export $(shell sed 's/=.*//' defaults.env)

all: move-monitoring-to-marked-node manifests

manifests: tls-secret
	find manifests/ -type f | xargs cat | envsubst | kubectl apply -f -

move-monitoring-to-marked-node: mark-node
	./scripts/move-monitoring-to-marked-node.sh

mark-node:
	./scripts/mark-node.sh

hook-overload-frontend:
	LOAD_USER_COUNT=100 LOAD_REPLICAS=4 envsubst < manifests/load/load-deployment.yml | kubectl apply -f -

hook-overload-frontend-revert:
	envsubst < manifests/load/load-deployment.yml | kubectl apply -f -

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
	find manifests/ -type f | xargs cat | envsubst | kubectl delete -f -
	rm build

tls-secret: build/tls.crt build/tls.key
	kubectl create secret tls tls-secret --cert=build/tls.crt --key=build/tls.key || true

build/tls.crt build/tls.key: build
	openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout build/tls.key -out build/tls.crt -subj '/CN=localhost'

build:
	mkdir -p build

.PHONY: deploy clean tls-secret
