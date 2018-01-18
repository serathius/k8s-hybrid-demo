all: deploy

deploy:
	kubectl apply -f manifests/

clean:
	kubectl delete -f manifests/

.PHONY: deploy clean
