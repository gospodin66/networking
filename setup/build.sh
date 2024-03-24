#!/bin/bash
start=$SECONDS
net_prefix="networking"
docker_env_path=".."
dockerfile_path="../Dockerfile"
docker_img="$net_prefix:1.0"
storage_path="/home/node/storage"
net1_containers_num=3
net2_containers_num=3
total_containers=$(($net1_containers_num + $net2_containers_num + 2))

declare -A net1=(
  [name]="net1"
  [network]="10.110.0.0/16"
  [gateway]="10.110.0.1"
  [probe]="10.110.0.110"
)
declare -A net2=(
  [name]="net2"
  [network]="10.120.0.0/16"
  [gateway]="10.120.0.1"
  [probe]="10.120.0.120"
)
declare -A router=(
  [name]="router-net"
  [network]="10.140.0.0/16"
  [gateway]="10.140.0.1"
  [ip]="10.140.0.140"
)

docker stop $(docker ps -q) 2>/dev/null; \
docker rm $(docker ps -q) 2>/dev/null
echo "-- building docker image [$docker_img].."

echo -e "\n--------------------\nBuilding $net_prefix and net-router images\n"
DOCKER_BUILDKIT=1 docker build -t $docker_img $docker_env_path -f $dockerfile_path
DOCKER_BUILDKIT=1 docker build -t net-router:1.0 .. -f ../Dockerfile-router

echo -e "\n--------------------\nCreating networks\n"
docker network prune --force
docker network create \
  --attachable \
  --driver=bridge \
  --subnet="${net1[network]}" \
  --ip-range="${net1[network]}" \
  --gateway="${net1[gateway]}" \
  "${net1[name]}"
docker network create \
  --attachable \
  --driver=bridge \
  --subnet="${net2[network]}" \
  --ip-range="${net2[network]}" \
  --gateway="${net2[gateway]}" \
  "${net2[name]}"
docker network create \
  --attachable \
  --driver=bridge \
  --subnet="${router[network]}" \
  --ip-range="${router[network]}" \
  --gateway="${router[gateway]}" \
  "${router[name]}"

echo -e "\n--------------------\nCreating volumes\n"
if ! docker volume ls | grep storage; then
    docker volume create \
                --driver=local \
                --opt type=none \
                --opt o=bind \
                --opt device=$(find ~/workspace/networking -type d -name storage_volume) \
                --name storage
fi

echo -e "\n--------------------\nRunning router ${router[network]}\n"
docker run \
      -dit \
      --init \
      --rm \
      --ip "${ip[router]}" \
      --network "${router[name]}" \
      --name net-router \
      --privileged \
      --cap-add=NET_ADMIN \
      --mount source=storage,destination="$storage_path" \
      net-router:1.0

echo -e "\n--------------------\nRunning net1 [${net1[probe]}] & [${net2[probe]}] probes\n"
docker run \
      -dit \
      --init \
      --rm \
      --ip "${net1[probe]}" \
      --network "${net1[name]}" \
      --name net1-probe \
      --privileged \
      --cap-add NET_ADMIN \
      --mount source=storage,destination="$storage_path" \
      "$net_prefix:1.0"
docker run \
      -dit \
      --init \
      --rm \
      --ip "${net2[probe]}" \
      --network "${net2[name]}" \
      --name net2-probe \
      --privileged \
      --cap-add NET_ADMIN \
      --mount source=storage,destination="$storage_path" \
      "$net_prefix:1.0"

echo -e "\n--------------------\nBase stack initialized successfuly\n"

for c in $(seq 1 1 $net1_containers_num); do
    net_index=1
    ip="10.110.0.11${c}"
    echo -e "Running node $ip"
    docker run \
        -dit \
        --init \
        --rm \
        --ip $ip \
        --network "net${net_index}" \
        --name "net${net_index}-machine${c}" \
        --privileged \
        --cap-add NET_ADMIN \
        --mount source=storage,destination="$storage_path" \
        "$docker_img"
done
for c in $(seq 1 1 $net2_containers_num); do
    net_index=2
    ip="10.120.0.12${c}"
    echo -e "Running node $ip"
    docker run \
        -dit \
        --init \
        --rm \
        --ip $ip \
        --network "net${net_index}" \
        --name "net${net_index}-machine${c}" \
        --privileged \
        --cap-add NET_ADMIN \
        --mount source=storage,destination=$storage_path \
        "$docker_img"
done
incr=0
while [ $(docker container ls | grep $net_prefix | wc -l) -lt "$total_containers" ]; do
    if ((incr > 20)); then
        echo -e "Error: Maximum container check iterations exceeded - There is something wrong with containers.\n"
        exit 1
    fi
    echo "-- waiting for containers: $(docker container ls | grep $net_prefix | wc -l)/$total_containers"
    sleep 1
    ((incr++))
done
echo "-- all containers are up: $(docker container ls | grep $net_prefix | wc -l)/$total_containers"
duration=$(( SECONDS - start ))
echo -e "-- duration: $duration seconds\n"
exit 0
