#!/bin/bash

N1_CONTAINERS=$(docker ps --filter "name=net1-machine" -q)
N2_CONTAINERS=$(docker ps --filter "name=net2-machine" -q)
ROUTER_CONTAINER=$(docker ps --filter "name=net-router" -q)

readarray -t n1_containers <<<"$N1_CONTAINERS"
readarray -t n2_containers <<<"$N2_CONTAINERS"

router_ip="10.140.0.140"
user='tunneller'

probe_n1_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' net1-probe)
probe_n2_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' net2-probe)
router_ips_str=$(docker inspect -f "{{range .NetworkSettings.Networks}}{{println .IPAddress}}{{end}}" "$ROUTER_CONTAINER")
readarray -t router_ips_arr <<<"$router_ips_str"
router_ip=""

# 10.140.0.0/16 has no connected machines except for router
# TODO: test p2p ssh

for r_ip in "${router_ips_arr[@]}" ;do
    if [ "${r_ip}" == "${router_ip}" ]; then
        router_ip=${r_ip}
    fi
done

echo -e "\nUsing router ip: ${router_ip}\n"

opts=("-o StrictHostKeyChecking=accept-new")
opts_str=$(printf -v string "%s$sep" "${opts[@]}")

cmd_ssh_copy_key="ssh-copy-id ${opts_str} -i /home/${user}/.ssh/id_rsa ${user}@${probe_n1_ip} 2>/dev/null; \
                  ssh-copy-id ${opts_str} -i /home/${user}/.ssh/id_rsa ${user}@${probe_n2_ip} 2>/dev/null;"

cmd_ssh_conn="set -ex; \
              ssh ${opts_str} ${user}@${probe_n1_ip} 'date'; \
              ssh ${opts_str} ${user}@${probe_n2_ip} 'date';"

# Copy each node's pub key to probe1/probe2
for node in "${n1_containers[@]}" ;do
    echo -e "Node ${node} copying ssh key to: ${probe_n1_ip}, ${probe_n2_ip} & router..."
    docker exec -it ${node} sh -c "${cmd_ssh_copy_key}"
done
for node in "${n2_containers[@]}" ;do
    echo -e "Node ${node} copying ssh key to: ${probe_n1_ip}, ${probe_n2_ip} & router ..."
    docker exec -it ${node} sh -c "${cmd_ssh_copy_key}"
done

# Test ssh to probe1/probe2
for node in "${n1_containers[@]}" ;do
    echo -e "Node ${node} ssh connect to: ${probe_n1_ip}, ${probe_n2_ip} & router ..."
    docker exec ${node} sh -c "${cmd_ssh_conn}"
done
for node in "${n2_containers[@]}" ;do
    echo -e "Node ${node} ssh connect to: ${probe_n1_ip}, ${probe_n2_ip} & router ..."
    docker exec ${node} sh -c "${cmd_ssh_conn}"
done
