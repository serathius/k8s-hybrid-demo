include defaults.env
export $(shell sed 's/=.*//' defaults.env)

all: deploy

deploy:
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

.PHONY: deploy clean
