#!/bin/bash
# Récupérer les informations sur le service Nextcloud (ID, nom, image, nœud, état désiré, état actuel)
service_info=$(sudo docker service ps nextcloud_stack_nextcloud --format "{{ .ID }} {{ .Node }} {{ .CurrentState }}" | grep "Running")

# Vérifier si le service est bien en état 'Running'
if [[ -n "$service_info" ]]; then
    # Extraire le nœud sur lequel le service est en cours d'exécution
    service_node=$(echo $service_info | awk '{print $2}')

    echo "Le service Nextcloud est en cours d'exécution sur le nœud : $service_node"
else
    echo "Le service Nextcloud n'est pas en cours d'exécution."
    exit 1
fi
