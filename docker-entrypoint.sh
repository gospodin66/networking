#!/bin/sh
set -ex

user='tunneller'
UID=8922
GID=8922

/usr/local/bin/docker-entrypoint-ssh-keygen.sh

chown -R "${UID}":"${GID}" /home/"${user}"

/usr/sbin/sshd -D

service ssh restart

echo "Starting service ..."
exec "$@"
