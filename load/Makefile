VERSION?=v1
REGISTRY?=gcr.io/siarkowicz-test-191814

release: clean build push clean

# builds a docker image that builds the app and packages it into a minimal docker image
build:
	docker build --pull --rm --force-rm -t "${REGISTRY}/load:${VERSION}" .

# push the image to an registry
push:
	gcloud docker -- push ${REGISTRY}/load:${VERSION}

deploy:
	kubectl apply -f load-controller.yml

# remove previous images and containers
clean:
	docker rmi -f "${REGISTRY}/load:${VERSION}" || true
	kubectl delete -f load-controller.yml

.PHONY: release clean build push deploy
