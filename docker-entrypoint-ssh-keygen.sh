#!/bin/sh

user='tunneller'

# craft node keys
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi

if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

if [ ! -f "/etc/ssh/ssh_host_ecdsa_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa
fi

if [ ! -f "/etc/ssh/ssh_host_ed25519_key" ]; then
    ssh-keygen -vvv -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
fi

# craft tunneller keys
if [ ! -f "/home/${user}/.ssh/id_rsa" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_rsa" -N '' -t rsa
fi

if [ ! -f "/home/${user}/.ssh/id_dsa" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_dsa" -N '' -t dsa
fi

if [ ! -f "/home/${user}/.ssh/id_ecdsa" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_ecdsa" -N '' -t ecdsa
fi

if [ ! -f "/home/${user}/.ssh/id_ed25519" ]; then
    ssh-keygen -vvv -f "/home/${user}/.ssh/id_ed25519" -N '' -t ed25519
fi