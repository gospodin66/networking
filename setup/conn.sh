#!/bin/bash

N1_CONTAINERS=$(docker ps --filter "name=net1-machine" -q)
N2_CONTAINERS=$(docker ps --filter "name=net2-machine" -q)
ROUTER_CONTAINER=$(docker ps --filter "name=net-router" -q)
ASSETS_PATH="../assets"
NET1_IPS="ips-eth1.txt"
NET2_IPS="ips-eth2.txt"

readarray -t n1_containers <<<"$N1_CONTAINERS"
readarray -t n2_containers <<<"$N2_CONTAINERS"

loop_network(){
    net_containers=("$@")
    for node in "${net_containers[@]}" ;do
        docker cp "$ASSETS_PATH/$NET1_IPS" "$node:/home/node/storage/$NET1_IPS"
        docker cp "$ASSETS_PATH/$NET2_IPS" "$node:/home/node/storage/$NET2_IPS"
        docker exec $node sh -c "\
            loop_ips(){
                while read -r line; do
                    printf '\n\t%s::' \"\$line\" && \
                    ping -W1 -i0.2 -4 -c2 -n \"\$line\" &>/dev/null && \
                    printf 'success' || printf 'unreachable'
                done < \"\$1\" 
            }
            hname=\$(hostname)
            hip=\$(hostname -i)
            printf 'node %s [ %s] discovering:' \"\$hname\" \"\$hip\"
            loop_ips \"/home/node/storage/$NET1_IPS\";
            loop_ips \"/home/node/storage/$NET2_IPS\";"
        printf '\n'
    done
}

echo "---------- copying [$NET1_IPS|$NET2_IPS] from $ROUTER_CONTAINER to host.."
docker cp "$ROUTER_CONTAINER:/home/node/storage/$NET1_IPS" "$ASSETS_PATH/$NET1_IPS"
docker cp "$ROUTER_CONTAINER:/home/node/storage/$NET2_IPS" "$ASSETS_PATH/$NET2_IPS"

echo "---------- loop-connecting containers.."
start=$SECONDS && loop_network "${n1_containers[@]}" && duration1=$(( SECONDS - start ))
start=$SECONDS && loop_network "${n2_containers[@]}" && duration2=$(( SECONDS - start ))

echo -e "---------- duration net-1: $duration1 seconds\n---------- duration net-2: $duration2 seconds\n"
