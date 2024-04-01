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
iface_net1="10.110.0.1"
iface_net2="10.120.0.1"
iface_routernet="10.140.0.140"
netmask="255.255.0.0"
local_port_range=$(echo $(cat /proc/sys/net/ipv4/ip_local_port_range) | tr -s ' ' | tr ' ' ':')
port_range_min=$((${local_port_range%%:*}))
port_range_max=$((${local_port_range#*:}))

echo "Checking iptables packages.."
for p in ${packages[@]}; do
    echo -e "Installing package: $p"
    if ! apk add $p &>/dev/null; then
        echo "Failed to install package $p - Exiting.."
        exit 1
    else
        echo "Package $p installed."
    fi
done
echo "Packages installed: $(printf '%s ' ${packages[@]})"

sysctl net.ipv4.tcp_syncookies=1
sysctl net.ipv4.conf.all.forwarding=1

echo "Configuring up routing table.."
ifconfig eth1 "$iface_net1" netmask "$netmask"
ifconfig eth2 "$iface_net2" netmask "$netmask"

echo "Creating routing IPs.."
ip -4 addr add "$iface_net1/16" dev eth1 
ip -4 addr add "$iface_net2/16" dev eth2 

echo "Configuring routes.."
ip route add default via "$iface_routernet" dev eth0 
ip route add "${whitelisted_net["net1"]}" via "$iface_net1" dev eth1
ip route add "${whitelisted_net["net2"]}" via "$iface_net2" dev eth2
ip -4 r && ip -4 n

echo "Clearing firewall.."
iptables -F && ip6tables -F
iptables -X && ip6tables -X
iptables -F -t nat && ip6tables -F -t nat
iptables -X -t nat && ip6tables -X -t nat
iptables -F -t mangle && ip6tables -F -t mangle
iptables -X -t mangle && ip6tables -X -t mangle

echo "Setting up firewall.."
# default drop all  
iptables -P INPUT ACCEPT && ip6tables -P INPUT DROP
iptables -P OUTPUT ACCEPT && ip6tables -P OUTPUT DROP
iptables -P FORWARD ACCEPT && ip6tables -P FORWARD DROP

for i in "${!whitelisted_net[@]}"; do
    # mask the requests from inside the LAN with the external IP of NAT router VM.
    if [ $i == "routernet" ]; then
        continue
    fi
    iptables -t nat -s "${whitelisted_net[$i]}" -A POSTROUTING -j MASQUERADE
done

# ACCEPT LOOPBACK
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# FIRST PACKET HAS TO BE TCP SYN
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
# DROP FRAGMENTS
iptables -A INPUT -f -j DROP
# DROP XMAS PACKETS
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# DROP NULL PACKETS
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
# DROP EXCESSIVE TCP RST PACKETS
iptables -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
# syn-flood protection:
iptables -A INPUT -p tcp -m state --state NEW -m limit --limit 20/second --limit-burst 100 -j ACCEPT
# DROP ALL INVALID PACKETS
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP
# ICMP SMURF ATTACKS + PING OF DEATH + RATE LIMIT THE REST:
# address-mask-request - normally sent by a host to a router in order to obtain an appropriate subnet mask
iptables -A INPUT -p icmp --icmp-type address-mask-request -j DROP
# timestamp-request - ability to determine the length of time that ICMP query messages spend in transit
iptables -A INPUT -p icmp --icmp-type timestamp-request -j DROP
# router-solicitation - sent from a computer host to any routers on the local area network to request that they advertise their presence on the network
iptables -A INPUT -p icmp --icmp-type router-solicitation -j DROP
iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 1/s -j DROP
iptables -A INPUT -p icmp -m limit --limit 20/second -j ACCEPT
# furtive port scanner:
iptables -A FORWARD -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s -j DROP;
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
# block outgoing emails
iptables -A OUTPUT -p tcp --dport ${port["smtp"]} -j REJECT
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
# Allow forwarding of all related and established traffic:
iptables -A FORWARD -s ${whitelisted_net["net1"]} -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s ${whitelisted_net["net2"]} -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -d ${whitelisted_net["net1"]} -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -d ${whitelisted_net["net2"]} -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
# custom routing net1<->net2:
iptables -A FORWARD -s ${whitelisted_net["net1"]} -d ${whitelisted_net["net1"]} -j ACCEPT
iptables -A FORWARD -s ${whitelisted_net["net1"]} -d ${whitelisted_net["net2"]} -j ACCEPT
iptables -A FORWARD -s ${whitelisted_net["net2"]} -d ${whitelisted_net["net1"]} -j ACCEPT
iptables -A FORWARD -s ${whitelisted_net["net2"]} -d ${whitelisted_net["net2"]} -j ACCEPT
# allow established connections:
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# allow ICMP traffic:
iptables -A FORWARD -p icmp -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT
# allow outgoing TCP/UDP traffic $(cat /proc/sys/net/ipv4/ip_local_port_range):
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
