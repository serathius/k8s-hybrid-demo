include defaults.env
export $(shell sed 's/=.*//' defaults.env)

all: deploy

deploy:
	find manifests/ -type f | xargs cat | envsubst | kubectl apply -f -

clean:
	find manifests/ -type f | xargs cat | envsubst | kubectl delete -f -

.PHONY: deploy clean
