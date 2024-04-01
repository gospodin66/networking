#!/bin/sh
user="user"
jump="jump"
dest="dest"
docker container stop $user $jump $dest;
docker container rm $user $jump $dest;
storage_path="/home/node/storage"
DOCKER_BUILDKIT=1 docker build -t $user:1.0 . -f DockerfileUSER.dockerfile && \
DOCKER_BUILDKIT=1 docker build -t $jump:1.0 . -f DockerfileJUMP.dockerfile && \
DOCKER_BUILDKIT=1 docker build -t $dest:1.0 . -f DockerfileDEST.dockerfile;
docker run \
        -dit \
        --rm \
        --name $user \
        --cap-add NET_ADMIN \
        --mount source=storage,destination="$storage_path" \
        $user:1.0 && \
docker run \
        -dit \
        --rm \
        --name $jump \
        --cap-add NET_ADMIN \
        --mount source=storage,destination="$storage_path" \
        $jump:1.0 && \
docker run \
        -dit \
        --rm \
        --name $dest \
        --cap-add NET_ADMIN \
        --mount source=storage,destination="$storage_path" \
        $dest:1.0;
# configure .config with new hosntames
jump_hostname=`docker exec $jump hostname`
dest_hostname=`docker exec $dest hostname`
docker exec $user sed -i -e 's/JUMP_HOST=*/JUMP_HOST='${jump_hostname}'/g' /home/tunnel/.config
docker exec $user sed -i -e 's/DEST_HOST=*/DEST_HOST='${dest_hostname}'/g' /home/tunnel/.config
### if combined with `networking` project
if [ "`docker ps -a -q -f name=net-router`" ]; then

    # connect ssh_user to router network => access to net1 & net2 nodes
    docker network connect router-net $dest_hostname

    echo "****************************************************"
    echo "router is available: configuring & opening tunnels.."
    echo "(user will be prompted to generate & use passphrase)"
    echo "****************************************************"
    ./scripts/open-tunnels.sh
fi
#echo "Setting up firewall in containers"
#containers=("$user" "$jump" "$dest")
#for c in ${containers[@]}; do
#    docker cp ../setup/firewall.sh $c:/root/
#    docker exec $c bash /root/firewall.sh
#done
docker inspect --format '{{.Name}}: {{range $k, $v := .NetworkSettings.Networks}}[{{$k}}:{{.IPAddress}}] {{end}}' $(docker ps -q)
echo "Tunnel stack setup complete."
exit 0;