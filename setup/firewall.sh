#!/bin/bash
if [ "$EUID" -ne 0 ]
    then echo "This script needs to be ran as root"
    exit 1
fi
declare -a packages=(
    "iptables" 
    "ip6tables" 
)
declare -A whitelisted_net=(
    [net1]="10.110.0.0/16"
    [net2]="10.120.0.0/16"
    [routernet]="10.140.0.0/16"
)
declare -A port=(
    [ssh]=22
    [smtp]=25
    [dns]=53
    [http]=80
    [https]=443
    [imap]=143
)
local_port_range=$(echo $(cat /proc/sys/net/ipv4/ip_local_port_range) | tr -s ' ' | tr ' ' ':')
port_range_min=$((${local_port_range%%:*}))
port_range_max=$((${local_port_range#*:}))

echo "Checking iptables packages.."
for p in ${packages[@]}; do
    echo "Installing package: $p"
    if ! apk add $p &>/dev/null; then
        echo "Failed to install package $p"
    fi
done
echo "Packages installed: $(printf '%s ' ${packages[@]})"

echo "Disabling forwarding.."
sysctl net.ipv4.conf.all.forwarding=0 &>/dev/null

echo "Clearing firewall.."
iptables -F && ip6tables -F
#iptables -X && ip6tables -X
iptables -F -t nat && ip6tables -F -t nat
#iptables -X -t nat && ip6tables -X -t nat
#iptables -F -t mangle && ip6tables -F -t mangle
#iptables -X -t mangle && ip6tables -X -t mangle

echo "Setting up firewall.."
# default drop all  
iptables -P INPUT ACCEPT && ip6tables -P INPUT DROP
iptables -P OUTPUT ACCEPT && ip6tables -P OUTPUT DROP
iptables -P FORWARD DROP && ip6tables -P FORWARD DROP

# ACCEPT LOOPBACK
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# FIRST PACKET HAS TO BE TCP SYN
#iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
## DROP FRAGMENTS
#iptables -A INPUT -f -j DROP
## DROP XMAS PACKETS
#iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
## DROP NULL PACKETS
#iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# DROP EXCESSIVE TCP RST PACKETS
#iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
# syn-flood protection:
#iptables -A INPUT -p tcp -m state --state NEW -m limit --limit 10/second --limit-burst 100 -j ACCEPT
# furtive port scanner:
#iptables -A FORWARD -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j DROP;
# DROP ALL INVALID PACKETS
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP
# ICMP SMURF ATTACKS + PING OF DEATH + RATE LIMIT THE REST:
#iptables -A INPUT -p icmp --icmp-type address-mask-request -j DROP
#iptables -A INPUT -p icmp --icmp-type timestamp-request -j DROP
#iptables -A INPUT -p icmp --icmp-type router-solicitation -j DROP
#iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j DROP
#iptables -A INPUT -p icmp -m limit --limit 30/second -j ACCEPT
# bruteforce attacks: 
#iptables -A INPUT -p tcp --dport ${port["ssh"]} -m state --state NEW -m recent --set --name DDOS-SSH
#iptables -A INPUT -p tcp --dport ${port["ssh"]} -m state --state NEW -m recent --update --seconds 60 --hitcount 5  --name DDOS-SSH -j DROP
#iptables -A INPUT -p tcp --dport ${port["dns"]} -m state --state NEW -m recent --set --name DDOS-DNS
#iptables -A INPUT -p tcp --dport ${port["dns"]} -m state --state NEW  -m recent --update --seconds 20 --hitcount 10 --name DDOS-DNS -j DROP
#iptables -A INPUT -p tcp --dport ${port["smtp"]} -m state --state NEW -m recent --set --name DDOS-SMTP
#iptables -A INPUT -p tcp --dport ${port["smtp"]} -m state --state NEW -m recent --update --seconds 20 --hitcount 10 --name DDOS-SMTP -j DROP
#iptables -A INPUT -p tcp --dport ${port["imap"]} -m state --state NEW -m recent --set --name DDOS-IMAP
#iptables -A INPUT -p tcp --dport ${port["imap"]} -m state --state NEW -m recent --update --seconds 20 --hitcount 10 --name DDOS-IMAP -j DROP
#iptables -A INPUT -p tcp --dport ${port["http"]} -m state --state NEW -m recent --set --name DDOS-HTTP
#iptables -A INPUT -p tcp --dport ${port["http"]} -m state --state NEW -m recent --update --seconds 5  --hitcount 10 --name DDOS-HTTP -j DROP
#iptables -A INPUT -p tcp --dport ${port["https"]} -m state --state NEW -m recent --set --name DDOS-HTTPS
#iptables -A INPUT -p tcp --dport ${port["https"]} -m state --state NEW -m recent --update --seconds 5 --hitcount 10 --name DDOS-HTTPS -j DROP
# DOS:
#iptables -A INPUT -p tcp --syn --dport ${port["https"]} -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
#iptables -A INPUT -p tcp --syn --dport ${port["http"]} -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
#iptables -A INPUT -p tcp --syn --dport ${port["dns"]} -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
#iptables -A INPUT -p tcp --syn --dport ${port["smtp"]} -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
#iptables -A INPUT -p tcp --syn --dport ${port["ssh"]} -m connlimit --connlimit-above 15 --connlimit-mask 32 -j REJECT --reject-with tcp-reset
#iptables -A INPUT -m state --state RELATED,ESTABLISHED -m limit --limit 20/second --limit-burst 180 -j ACCEPT
# IMAP:
iptables -A INPUT -p tcp --dport ${port["imap"]} -s ${whitelisted_net["net1"]} -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["imap"]} -s ${whitelisted_net["net2"]} -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["imap"]} -s ${whitelisted_net["routernet"]} -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["imap"]} -j DROP
# SMTP:
iptables -A INPUT -p tcp --dport ${port["smtp"]} -s ${whitelisted_net["net1"]} -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["smtp"]} -s ${whitelisted_net["net2"]} -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["smtp"]} -s ${whitelisted_net["routernet"]} -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["smtp"]} -j DROP
# SSH:
iptables -A INPUT -p tcp --dport ${port["ssh"]} -m state --state NEW -m tcp -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["ssh"]} --syn -m connlimit --connlimit-above 3 -j REJECT
iptables -A INPUT -p tcp --dport ${port["ssh"]} -s ${whitelisted_net["net1"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["ssh"]} -s ${whitelisted_net["net1"]} -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["ssh"]} -s ${whitelisted_net["net2"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["ssh"]} -s ${whitelisted_net["net2"]} -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["ssh"]} -s ${whitelisted_net["routernet"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["ssh"]} -s ${whitelisted_net["routernet"]} -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["ssh"]} -j DROP
# DNS:
iptables -A INPUT -p tcp --dport ${port["dns"]} -s ${whitelisted_net["net1"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp --dport ${port["dns"]} -s ${whitelisted_net["net1"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["dns"]} -s ${whitelisted_net["net2"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp --dport ${port["dns"]} -s ${whitelisted_net["net2"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["dns"]} -s ${whitelisted_net["routernet"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p udp --dport ${port["dns"]} -s ${whitelisted_net["routernet"]} -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp --dport ${port["dns"]} -j DROP
iptables -A INPUT -p udp --dport ${port["dns"]} -j DROP
# allow established connections:
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# allow otgoing ICMP traffic:
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT
# allow outgoijg tcp|udp from local port range
iptables -A OUTPUT -p tcp --sport $port_range_min:$port_range_max -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp --sport $port_range_min:$port_range_max -m state --state NEW -j ACCEPT
# logging
iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "iptables Packet Dropped: " --log-level 7
iptables -A LOGGING -j DROP

/sbin/iptables-save 1>/dev/null
echo "Firewall configured successfuly - $((`iptables -L -n | wc -l` -6)) rules applied."
exit 0
