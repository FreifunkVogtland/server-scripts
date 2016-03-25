#!/bin/bash

gre_init() {
	if [ ! "$WANIF" ] || [ ! "$WANIP" ]; then
		log_fatal_error "Missing WANIF or WANIP - please check configuration!"
	fi
}

# Get running GRE interface names
gre_get_running_ifnames() {
	local running_ifnames=$(grep "gre-" /proc/net/dev | sed -e "s/:.*//g")
	echo "$running_ifnames"
}

# Add GRE tunnel
# 	$1		Interface name
# 	$2		Peer IPv4 address
gre_add_tunnel() {
	gre_init
	local ipL1=$(echo $WANIP | awk -F '.' '{print $3}')
	local ipL2=$(echo $WANIP | awk -F '.' '{print $4}')
	local ipR1=$(echo $2 | awk -F '.' '{print $3}')
	local ipR2=$(echo $2 | awk -F '.' '{print $4}')
	ip link add $1 type gretap remote $2 local $WANIP ttl 255
	ip addr add 169.254.${ipL1}.${ipL2} peer 169.254.${ipR1}.${ipR2}/32 scope link dev $1
	ip link set mtu 1400 up dev $1
}

# Remove GRE tunnel
# 	$1		Interface name
gre_del_tunnel() {
	ip link delete $1 >> /dev/null 2>&1
}

# Checks if GRE tunnel is still alive
#	$1		Interface name
gre_check_tunnel() {
	local result=false
	local pingCheck=$(ping6 -c3 -i1 ff02::2%${1} | grep -c DUP)
	if [ $pingCheck -gt 0 ]; then
		result=true
	fi
	echo "$result"
}

# Build GRE tunnels to remote backbone servers
gre_add_all_tunnels() {
	if [ ! ${#GRE_PEERS[@]} -gt 0 ]; then
		log_fatal_error "Missing GRE_PEERS - please check configuration!"
	fi
	for p in "${GRE_PEERS[@]}"; do
		remoteHost=$(echo $p | awk -F ':' '{print $1}')
		remoteIP=$(echo $p | awk -F ':' '{print $2}')
		if [ "$remoteHost" ] && [ "$remoteIP" ]; then
			# Do not add ourselves as a peer
			if [ "$remoteIP" != "$WANIP" ]; then
				gre_add_tunnel "gre-${remoteHost}" "$remoteIP"
			fi
		else
			log_error "Syntax error in peer definition: ${p}"
		fi
	done
}

# Remove all running GRE tunnels
gre_del_all_tunnels() {
	running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		gre_del_tunnel "${i}"
	done
}
