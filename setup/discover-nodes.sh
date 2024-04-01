#!/bin/sh

##########################
### Executes in containers
##########################

INTERFACE_1="eth1"
INTERFACE_2="eth2"
NET1_HOSTS="10.110.0.1-255"
NET2_HOSTS="10.120.0.1-255"
HOSTS_STATUS="/home/node/storage/hosts-status"
NET1_IPS="/home/node/storage/ips-$INTERFACE_1.txt"
NET2_IPS="/home/node/storage/ips-$INTERFACE_2.txt"

if [ ! -f "$NET1_IPS" ];then 
    touch "$NET1_IPS"
fi
if [ ! -f "$NET2_IPS" ];then 
    touch "$NET2_IPS"
fi

nmap -vvv -n -sn $NET1_HOSTS -oG - \
| awk '/Up$/{print $2}' \
| sort -V \
| tee "$NET1_IPS";

nmap -vvv -n -sn $NET2_HOSTS -oG - \
| awk '/Up$/{print $2}' \
| sort -V \
| tee "$NET2_IPS";

printf 'net-router ping:'
while read -r line; do
    printf '\n\t%s::' "$line" && \
    ping -W1 -4 -c1 -I eth1 "$line" | tee "${HOSTS_STATUS}-${line}.txt" &>/dev/null && \
    printf 'success' || printf 'unreachable'
done < "$NET1_IPS";
while read -r line; do
    printf '\n\t%s::' "$line" && \
    ping -W1 -4 -c1 -I eth2 "$line" | tee "${HOSTS_STATUS}-${line}.txt" &>/dev/null  && \
    printf 'success' || printf 'unreachable'
done < "$NET2_IPS";

echo -e "\ndiscovery finished.\n"
