#!/bin/bash

## Configure cluster name using the template variable ${ecs_cluster_name}
echo ECS_CLUSTER='mateusclira-cluster' >> /etc/ecs/ecs.config

cat <<'EOF' >> /etc/ecs/ecs.config
ECS_WARM_POOLS_CHECK=true
EOF
