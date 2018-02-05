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

clean:
	find manifests/ -type f | xargs cat | envsubst | kubectl delete -f -

.PHONY: deploy clean
