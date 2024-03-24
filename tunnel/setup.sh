#!/bin/sh
docker container stop ssh-user ssh-jump ssh-dest;
docker container rm ssh-user ssh-jump ssh-dest;
DOCKER_BUILDKIT=1 docker build -t ssh-user:1.0 . -f DockerfileUSER.dockerfile && \
DOCKER_BUILDKIT=1 docker build -t ssh-jump:1.0 . -f DockerfileJUMP.dockerfile && \
DOCKER_BUILDKIT=1 docker build -t ssh-dest:1.0 . -f DockerfileDEST.dockerfile;
docker run -d --name ssh-user --cap-add NET_ADMIN ssh-user:1.0 && \
docker run -d --name ssh-jump --cap-add NET_ADMIN ssh-jump:1.0 && \
docker run -d --name ssh-dest --cap-add NET_ADMIN ssh-dest:1.0;
# configure .config with new hosntames
jump=`docker exec ssh-jump hostname`
dest=`docker exec ssh-dest hostname`
docker exec ssh-user sed -i -e 's/JUMP_HOST=*/JUMP_HOST='${jump}'/g' /home/tunnel/.config
docker exec ssh-user sed -i -e 's/DEST_HOST=*/DEST_HOST='${dest}'/g' /home/tunnel/.config
### if combined with `networking` project
if [ "`docker ps -a -q -f name=net-router`" ]; then

    # connect ssh_user to router network => access to net1 & net2 nodes
    docker network connect router-net ssh-dest

    echo "****************************************************"
    echo "router is available: configuring & opening tunnels.."
    echo "(user will be prompted to generate & use passphrase)"
    echo "****************************************************"
    ./scripts/open-tunnels.sh
fi
echo "Setting up firewall in containers"
containers=("ssh-user" "ssh-jump" "ssh-dest")
for c in ${containers[@]}; do
    docker cp ../setup/firewall.sh $c:/root/
    docker exec $c bash /root/firewall.sh
done
docker inspect --format '{{.Name}}: {{range $k, $v := .NetworkSettings.Networks}}[{{$k}}:{{.IPAddress}}] {{end}}' $(docker ps -q)
echo "Tunnel stack setup complete."
exit 0;