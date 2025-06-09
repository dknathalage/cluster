ANSIBLE_DIR=./ansible

# Infrastructure provisioning
ansible.ping:
	ansible -i ${ANSIBLE_DIR}/inventory.ini all -m ping

ansible.cluster.setup:
	ansible-playbook -i ${ANSIBLE_DIR}/inventory.ini ${ANSIBLE_DIR}/playbook/k8s-cluster-setup.yaml --ask-become-pass

# Flux GitOps bootstrap (one-time manual installation)
flux.bootstrap.local:
	kubectl apply -k clusters/local/bootstrap

# Generic bootstrap for any cluster
flux.bootstrap:
	@echo "Usage: make flux.bootstrap.<cluster-name>"
	@echo "Available clusters:"
	@find clusters -maxdepth 1 -type d -name "local" | sed 's/clusters\//  /'

# Flux management commands
flux.status:
	kubectl get gitrepository,kustomization -n flux-system

flux.status.local:
	kubectl get gitrepository,kustomization -n flux-system --context=local 2>/dev/null || kubectl get gitrepository,kustomization -n flux-system

flux.reconcile:
	flux reconcile source git flux-system

flux.reconcile.local:
	flux reconcile source git flux-system --context=local 2>/dev/null || flux reconcile source git flux-system