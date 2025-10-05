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
	kubectl apply -f k8s/camera-uploader.yaml
	
deploy1:
	kubectl apply -f k8s/relay.yaml

undeploy:
	kubectl delete -f k8s/relay.yaml
	kubectl delete -f k8s/camera-uploader.yaml
