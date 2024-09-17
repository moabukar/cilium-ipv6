# Makefile to bootstrap the lab environment

.PHONY: kind-cluster
up:
	kind create cluster --config kind.yaml

.PHONY: cilium-install
cilium-install:
	cilium install \
		--set kubeProxyReplacement=true \
		--set k8sServiceHost=kind-control-plane \
		--set k8sServicePort=6443 \
		--set ipv6.enabled=true

.PHONY: cilium-status
cilium-status:
	cilium status --wait

.PHONY: cilium-config
cilium-config:
	cilium config view | grep ipv6

.PHONY: cilium-hubble
cilium-hubble:
	cilium hubble enable --ui

.PHONY: cilium-hubble-port-forward
cilium-hubble-port-forward:
	cilium hubble port-forward &

.PHONY: down
down:
	kind delete cluster
