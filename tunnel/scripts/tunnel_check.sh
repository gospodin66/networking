#!/bin/bash

argc=$#

if [ "$argc" -lt 2 ]; then
    echo "Please enter <config_file> <email_feature>(optional 0|1)"
    exit 1
fi

config_file="$1"
mail_alert_feature="$2"

if [ ! -f "$config_file" ]; then
    echo "Error: Config file not found."
    exit 1
fi

if [ "$mail_alert_feature" == "1" ]; then
    mail_alert_feature=1
else
    mail_alert_feature=0
fi

source "$config_file"

email_notification="/home/$LOCAL_USER/notification_sent"
ssh_tunnel_script="/home/$LOCAL_USER/ssh_tunnel"

function alert_tunnel_down() {
    subj="ENI Tunnel Is Down\n\nIt looks like the ENI tunnel is not working, please reopen it."
    python -c "import smtplib; \
                server=smtplib.SMTP( \
                    \"$SMTP_HOST\", \
                    timeout=30 \
                ); \
                server.sendmail( \
                    \"$SENDER\", \
                    \"$RECEIVER\", \
                    \"Subject: $subj\" \
                )"
}


if [ -f "$SSH_TESTFILE" ]; then
    echo -e "\n\n"
    date -u
    echo -e "\n\n####################  The SSH tunnel is UP  ####################"
    echo -e "\n\n##############  I will check again in 15 minutes  ##############\n\n"
    if [ -f "$email_notification" ]; then
        rm "$email_notification"
    fi
elif [[ "$mail_alert_feature" -eq 1 && ! -f "$email_notification" ]]; then
    echo -e "\n####################  Sending notification  ####################\n"
    alert_tunnel_down
    touch "$email_notification"
else
    echo -e "\n\n"
    date -u
    echo -e "\n\n####################  The SSH tunnel is closed  ####################"
    echo -e "\n\n####################  Reopening the SSH tunnel  ####################\n\n"
    
    #for pid in $(pgrep -f tunnel | grep -v ^$$\$); do sudo kill -9 $pid; done
    
    sleep 5
    /usr/bin/expect "$ssh_tunnel_script" "$CONFIG_FILE" "$METHOD"
fi
