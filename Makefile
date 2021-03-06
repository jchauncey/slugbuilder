SHORT_NAME ?= slugbuilder

export GO15VENDOREXPERIMENT=1

# Note that Minio currently uses CGO.

VERSION ?= 0.0.1-$(shell date "+%Y%m%d%H%M%S")
LDFLAGS := "-s -X main.version=${VERSION}"
IMAGE_PREFIX ?= deis
BINDIR := ./rootfs/bin
DEV_REGISTRY ?= $$DEV_REGISTRY
DEIS_REGISTRY ?= ${DEV_REGISTRY}/

IMAGE := ${DEIS_REGISTRY}${IMAGE_PREFIX}/${SHORT_NAME}:${VERSION}
POD := manifests/deis-slugbuilder.yaml
SEC := manifests/deis-store-secret.yaml

all: build docker-build docker-push

bootstrap:
	@echo Nothing to do.

build:
	@echo Nothing to do.

docker-build:
	docker build --rm -t ${IMAGE} rootfs
	# These are both YAML specific
	# perl -pi -e "s|image: [a-z0-9.:]+\/deis\/${SHORT_NAME}:[0-9a-z-.]+|image: ${IMAGE}|g" ${RC}
	# perl -pi -e "s|release: [a-zA-Z0-9.+_-]+|release: ${VERSION}|g" ${RC}

docker-push:
	docker push ${IMAGE}

deploy: docker-build docker-push

kube-pod: kube-service
	kubectl create -f ${POD}

kube-secrets:
	- kubectl create -f ${SEC}

secrets:
	perl -pi -e "s|access-key-id: .+|access-key-id: ${key}|g" ${SEC}
	perl -pi -e "s|access-secret-key: .+|access-secret-key: ${secret}|g" ${SEC}
	echo ${key} ${secret}

kube-service: kube-secrets
	- kubectl create -f ${SVC}

kube-clean:
	- kubectl delete rc deis-${SHORT_NAME}-rc

test:
	@echo "Implement functional tests in _tests directory"

.PHONY: all bootstrap build docker-build docker-push deploy kube-pod kube-secrets \
	secrets kube-service kube-clean test
