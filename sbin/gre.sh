#!/bin/bash

gre_init() {
	export WANIF=$(ip route show default | grep ^default | sed -e "s/.*dev //g")
	export WANIP=$(ip address show dev $WANIF | grep -e "inet .* scope global" | awk '{print $2}' | sed -e "s/\/.*//g")
}

# Get peer hostnames from TXT record
gre_get_peers() {
	export PEERS=$(dig -t TXT backbone.routers.chemnitz.freifunk.net +short)
}

# Get running GRE interface names
gre_get_running_ifnames() {
	export RUNNING_IFNAMES=$(grep "gre-" /proc/net/dev | sed -e "s/:.*//g")
}

# Add GRE tunnel
# 	$1		Interface name
# 	$2		Peer IPv4 address
gre_add_tunnel() {
	gre_init
	ipL1=$(echo $WANIP | awk -F '.' '{print $3}')
	ipL2=$(echo $WANIP | awk -F '.' '{print $4}')
	ipR1=$(echo $2 | awk -F '.' '{print $3}')
	ipR2=$(echo $2 | awk -F '.' '{print $4}')
	ip link add $1 type gretap remote $2 local $WANIP ttl 255
	ip addr add 169.254.${ipL1}.${ipL2} peer 169.254.${ipR1}.${ipR2}/32 scope link dev $1
	ip link set mtu 1400 up dev $1
}

# Remove GRE tunnel
# 	$1		Interface name
gre_del_tunnel() {
	ip link delete $1 >> /dev/null 2>&1
}

# Add GRE tunnels to all backbone servers
gre_add_all_tunnels() {
	gre_get_peers
	for p in $PEERS; do
		remoteIP=$(dig -t A ${p}.routers.chemnitz.freifunk.net +short)
		if [ "$remoteIP" ]; then
			add_tunnel "gre-${p}" "$remoteIP"
		else
			log_error "No such peer: ${p}"
		fi
	done
}

# Remove all GRE tunnels
gre_del_all_tunnels() {
	gre_get_running_ifnames
	for i in $RUNNING_IFNAMES; do
		gre_del_tunnel "${i}"
	done
}