#!/bin/sh
ssh-keygen -A

alias ll="ls -ltra"

exec /usr/sbin/sshd -D -e "$@"