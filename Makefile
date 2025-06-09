ANSIBLE_DIR=./ansible

# Infrastructure provisioning
ansible.ping:
	ansible -i ${ANSIBLE_DIR}/inventory.ini all -m ping

ansible.cluster.setup:
	ansible-playbook -i ${ANSIBLE_DIR}/inventory.ini ${ANSIBLE_DIR}/playbook/k8s-cluster-setup.yaml --ask-become-pass

# Flux GitOps bootstrap (one-time manual installation)
flux.bootstrap:
	kubectl apply -f bootstrap/flux-system.yaml
	kubectl apply -f bootstrap/gotk-sync.yaml

# Flux management commands
flux.status:
	kubectl get gitrepository,kustomization -n flux-system

flux.reconcile:
	flux reconcile source git flux-system