#!/bin/bash

start=$SECONDS
N1_CONTAINERS=$(docker ps --filter "name=networking_n1" -q)
N2_CONTAINERS=$(docker ps --filter "name=networking_n2" -q)
ROUTER_CONTAINER=$(docker ps --filter "name=net-router" -q)
DISCOVER_SCRIPT="discover-nodes.sh"
readarray -t n1_containers <<<"$N1_CONTAINERS"
readarray -t n2_containers <<<"$N2_CONTAINERS"

echo "----- connecting nodes to net1.."
for node in "${n1_containers[@]}" ;do
    docker network connect net1 "$node" 2>/dev/null
done
echo "----- connecting nodes to net2.."
for node in "${n2_containers[@]}" ;do
    docker network connect net2 "$node" 2>/dev/null
done

echo -e "----- connecting net-router to [net-1|net-2].."
docker network connect net1 "$ROUTER_CONTAINER" 2>/dev/null
docker network connect net2 "$ROUTER_CONTAINER" 2>/dev/null

if [[ -z $(docker exec net-router ip r | grep eth0) || \
      -z $(docker exec net-router ip r | grep eth1) || \
      -z $(docker exec net-router ip r | grep eth2) ]];
then
    echo "ERROR: unable to fetch network interfaces.."
    exit 1
fi
echo -e "----- setting up firewall on $ROUTER_CONTAINER..\n"
docker exec -u0 net-router sh -c "/usr/local/bin/firewall-router.sh";

echo -e "----- executing [$DISCOVER_SCRIPT]..\n"
docker cp "$DISCOVER_SCRIPT" "$ROUTER_CONTAINER:/home/node/storage/$DISCOVER_SCRIPT"
docker exec $ROUTER_CONTAINER sh -c "\
    (chmod +x /home/node/storage/$DISCOVER_SCRIPT && \
     chown root:root /home/node/storage/$DISCOVER_SCRIPT) || exit 1; \
     /home/node/storage/$DISCOVER_SCRIPT"

duration=$(( SECONDS - start ))
echo -e "----- duration: $duration seconds\n"

