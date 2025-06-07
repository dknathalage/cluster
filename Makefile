ANSIBLE_DIR=./ansible
FLUX_DIR=./flux

ansible.ping:
	ansible -i ${ANSIBLE_DIR}/inventory.ini all -m ping

ansible.cluster.setup:
	ansible-playbook -i ${ANSIBLE_DIR}/inventory.ini ${ANSIBLE_DIR}/playbook/k8s-cluster-setup.yaml --ask-become-pass

flux.download:
	flux install --export > ${FLUX_DIR}/base/flux-system.yaml

flux.install:
	kubectl apply -k ${FLUX_DIR}/overlay/