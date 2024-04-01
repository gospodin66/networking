#!/bin/sh
set -e

user='tunneller'
UID=8922
GID=8922

# craft node keys
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa &>/dev/null
fi

if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa &>/dev/null
fi

if [ ! -f "/etc/ssh/ssh_host_ecdsa_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa &>/dev/null
fi

if [ ! -f "/etc/ssh/ssh_host_ed25519_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519 &>/dev/null
fi

# craft tunneller keys
if [ ! -f "/home/${user}/.ssh/id_rsa" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_rsa" -N '' -t rsa &>/dev/null
fi

if [ ! -f "/home/${user}/.ssh/id_dsa" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_dsa" -N '' -t dsa &>/dev/null
fi

if [ ! -f "/home/${user}/.ssh/id_ecdsa" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_ecdsa" -N '' -t ecdsa &>/dev/null
fi

if [ ! -f "/home/${user}/.ssh/id_ed25519" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_ed25519" -N '' -t ed25519 &>/dev/null
fi

chown -R "${UID}":"${GID}" /home/"${user}"

/usr/sbin/sshd -D

service ssh restart

echo "Starting service ..."
exec "$@"