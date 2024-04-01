#!/bin/bash

if [[ "$1" == "1" ]]; then install_tunnel=1; else install_tunnel=0; fi
path=("../logs" "../storage_volume" "../assets")

for p in "${path[@]}"; do
    if [ ! -d "$p" ]; then
        mkdir -m 744 "$p"
    fi
done 

echo -e "\n--------------------\nStopping containers\n"
docker container stop $(docker ps --format "{{.Names}}") 2>/dev/null

echo -e "\n--------------------\nBuilding\n"
(./build.sh | tee "${path[0]}/build.log") || exit 1;

echo -e "\n--------------------\nConnecting devices\n"
(./connect.sh | tee "${path[0]}/connect.log") || exit 1;

echo -e "\n--------------------\nDiscovering\n"
(./conn.sh | tee "${path[0]}/conn.log") || exit 1;

if (( $install_tunnel == 1 )); then
    cd ../tunnel;
    echo -e "\n--------------------\nSetting up tunnel\n" 
    (./setup.sh | tee "${path[0]}/tunnel.log") || exit 1;
fi

cd ..;

#for c in $(docker ps --format "{{.Names}}"); do
#    if [ $c == "net-router" ]; then
#        echo "---- Skipping $c container."
#        continue
#    fi
#    echo "---- Configuring firewall for container $c.."
#    docker cp setup/firewall.sh $c:/root/
#    docker exec -u0 $c bash -c "cd /root/; chmod 700 ./firewall.sh; ./firewall.sh;"
#    docker exec -u0 $c bash -c "echo \"\$(hostname -i): \$(iptables -L -n | wc -l) rules\"";
#done
#echo -e "\n--------------------nFirewall configured on all containers\n"

docker inspect \
    --format '{{.Name}}: {{range $k, $v := .NetworkSettings.Networks}}[{{$k}}:{{.IPAddress}}] {{end}}' \
    $(docker ps --format "{{.Names}}")



for c in $(docker ps --format "{{.Names}}"); do 
    if [ "${c}" == "user" ] || [ "${c}" == "jump" ] ||[ "${c}" == "dest" ]; then 
        docker cp /home/$USER/workspace/networking/setup/test.sh "$c:/usr/local/bin/test.sh"
        docker exec "$c" bash /usr/local/bin/test.sh
    else 
        docker cp /home/$USER/workspace/networking/setup/test.sh "$c:/home/tunneller/test.sh"
        docker exec "$c" bash /home/tunneller/test.sh
    fi
done


if [ $? -eq 0 ]; then
    echo -e "\n--------------------\nNetwork stack initialized successfuly\n"
    exit 0
fi
echo -e "\n--------------------\nNetwork stack initialized with error\n"
exit 1
