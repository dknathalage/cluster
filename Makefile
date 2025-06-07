ANSIBLE_DIR=./ansible

ansible.ping:
	ansible -i ${ANSIBLE_DIR}/inventory.ini all -m ping

ansible.cluster.setup:
	ansible-playbook -i ${ANSIBLE_DIR}/inventory.ini ${ANSIBLE_DIR}/playbook/k8s-cluster-setup.yaml --ask-become-pass