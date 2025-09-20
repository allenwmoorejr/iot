SHELL := /bin/bash
REGISTRY ?= docker.io
IMAGE_REPO ?= allenwayne/camera-uploader
TAG ?= latest
NAMESPACE ?= suite

.PHONY: build push deploy undeploy

build:
	docker build -t $(REGISTRY)/$(IMAGE_REPO):$(TAG) ./uploader

push:
	docker push $(REGISTRY)/$(IMAGE_REPO):$(TAG)

deploy:
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n $(NAMESPACE) apply -f k8s/camera-uploader.yaml
	kubectl -n $(NAMESPACE) apply -f k8s/relay.yaml

undeploy:
	kubectl -n $(NAMESPACE) delete -f k8s/relay.yaml --ignore-not-found
	kubectl -n $(NAMESPACE) delete -f k8s/camera-uploader.yaml --ignore-not-found
