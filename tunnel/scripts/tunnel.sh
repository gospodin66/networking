#!/bin/bash

argc=$#

if [ "$argc" -lt 1 ]; then
    echo "Please enter <config_file> <email_feature>(optional 0|1)"
    exit 1
fi

config_file="$1"

if [ ! -f "$config_file" ]; then
    echo "Error: Config file not found."
    exit 1
fi

source "$config_file"

ssh_tunnel_script="/home/$LOCAL_USER/ssh_tunnel"

if [ -f "$SSH_TESTFILE" ]; then
    echo -e "\n\n"
    echo -e "\n\n----- SSH tunnel is open\n\n"
    date -u
else
    echo -e "\n\n"
    date -u
    echo -e "\n\n----- Reopening the SSH tunnel\n\n"
    for pid in $(pgrep -f tunnel | grep -v ^$$\$); do kill -9 $pid; done
    sleep 5
    /usr/bin/expect "$ssh_tunnel_script" "$CONFIG_FILE" "$METHOD"
fi
