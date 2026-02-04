#!/bin/bash

# Demander une fois le mot de passe sudo et le stocker dans un fichier temporaire
echo "Veuillez entrer le mot de passe sudo :"
read -s SUDO_PASS

# Stocker le mot de passe dans un fichier temporaire avec des permissions sécurisées
echo "$SUDO_PASS" > /tmp/ansible_sudo_pass.txt
chmod 600 /tmp/ansible_sudo_pass.txt

# Exécuter les playbooks en utilisant le fichier de mot de passe pour --become-pass-file
ANSIBLE_BECOME_PASS_FILE="/tmp/ansible_sudo_pass.txt"

ansible-playbook -i inventory.ini uninstall_dependencies.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
ansible-playbook -i inventory.ini uninstall_galera.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
ansible-playbook -i inventory.ini uninstall_glusterfs.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
ansible-playbook -i inventory.ini uninstall_nextcloud.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
ansible-playbook -i inventory.ini uninstall_swarm.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
ansible-playbook -i inventory.ini uninstall_docker.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
#ansible-playbook -i inventory.ini uninstall_nextcloud_ingress.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
#ansible-playbook -i inventory.ini uninstall_nextcloud.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
#ansible-playbook -i inventory.ini uninstall_k3s.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
ansible-playbook -i inventory.ini uninstall_keepalived.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
#ansible-playbook -i inventory.ini uninstall_haproxy.yml --become-password-file $ANSIBLE_BECOME_PASS_FILE
# Supprimer le fichier de mot de passe temporaire
rm -f /tmp/ansible_sudo_pass.txt

