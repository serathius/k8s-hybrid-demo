include defaults.env
export $(shell sed 's/=.*//' defaults.env)

all: deploy

deploy: tls-secret
	find manifests/ -type f | xargs cat | envsubst | kubectl apply -f -

break-overload-frontend:
	LOAD_USER_COUNT=100 LOAD_REPLICAS=10 envsubst < manifests/load-deployment.json | kubectl apply -f -

break-node:
	./scripts/break-node.sh

break-node-revert:
	./scripts/break-node.sh REVERT

clear-database-recods:
	kubectl exec -it $$(kubectl get pods | grep redis-master | cut -f1 -d' ') -c redis-master -- redis-cli FLUSHALL

clean:
	find manifests/ -type f | xargs cat | envsubst | kubectl delete -f -

tls-secret: build/tls.crt build/tls.key
	kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key || true

build/tls.crt build/tls.key: build
	openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout build/tls.key -out build/tls.crt -subj '/CN=localhost'

build:
	mkdir -p build

.PHONY: deploy clean tls-secret
