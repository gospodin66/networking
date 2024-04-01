#!/bin/sh

##########################
### Executes in containers
##########################
# for c in $(docker ps -q); do docker cp /home/$USER/workspace/networking/setup/test.sh "$c:/home/tunneller/test.sh"; docker exec "$c" bash /home/tunneller/test.sh; done

INTERFACE_1="eth1"
INTERFACE_2="eth2"
NET1_IPS="/home/node/storage/ips-$INTERFACE_1.txt"
NET2_IPS="/home/node/storage/ips-$INTERFACE_2.txt"

echo -e "---------------\nmachine [ $(hostname -i)][net1] ping:"
while read -r line; do
    printf '\n\t%s::' "$line" && \
    ping -W1 -4 -c1 "$line" &>/dev/null && \
    printf 'success' || printf 'unreachable'
done < "$NET1_IPS";

echo -e "\n---------------\nmachine [ $(hostname -i)][net2] ping:"
while read -r line; do
    printf '\n\t%s::' "$line" && \
    ping -W1 -4 -c1 "$line" &>/dev/null && \
    printf 'success' || printf 'unreachable'
done < "$NET2_IPS";

echo -e "\nTest complete.\n"
exit 0
