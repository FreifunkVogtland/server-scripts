#!/bin/bash

# get own vxlan id
vxlan_own_id() {
	if [ ! ${#GRE_PEERS[@]} -gt 0 ]; then
		echo "Missing GRE_PEERS - please check configuration!"
		exit 1
	fi
	for p in "${GRE_PEERS[@]}"; do
		remoteHost=$(echo $p | awk -F ':' '{print $1}')
		remoteID=$(echo $p | awk -F ':' '{print $2}')
		remoteIP=$(echo $p | awk -F ':' '{print $3}')
		if [ "$remoteHost" ] && [ "$remoteIP" ]; then
			# Do not add ourselves as a peer
			if [ "$remoteIP" = "$WANIP" ]; then
				echo "$remoteID"
				return
			fi
		fi
	done

	echo "0"
}

vxlan_init() {
	if [ ! "$WANIF" ] || [ ! "$WANIP" ]; then
		echo "Missing WANIF or WANIP - please check configuration!"
		exit 1
	fi
}

# Get running vxlan interface names
vxlan_get_running_ifnames() {
	local running_ifnames=$(grep "vxlan0" /proc/net/dev | sed -e "s/:.*//g")
	echo "$running_ifnames"
}

# Build vxlan tunnels to remote backbone servers
vxlan_add_all_tunnels() {
	if [ ! ${#GRE_PEERS[@]} -gt 0 ]; then
		echo "Missing GRE_PEERS - please check configuration!"
		exit 1
	fi
	local ownID="$(vxlan_own_id)"

	/bin/ip link add vxlan0 type vxlan id "${VXLAN0_ID}" dev "${WANIF}" dstport 4789 nolearning
	/bin/ip link set dev vxlan0 address "$(printf "02:47:89:00:%02x:00" "$ownID" )"
	/bin/ip link set mtu 1426 up dev vxlan0

	for p in "${GRE_PEERS[@]}"; do
		remoteHost=$(echo $p | awk -F ':' '{print $1}')
		remoteID=$(echo $p | awk -F ':' '{print $2}')
		remoteIP=$(echo $p | awk -F ':' '{print $3}')
		if [ "$remoteHost" ] && [ "$remoteIP" ]; then
			# Do not add ourselves as a peer
			if [ "$remoteIP" != "$WANIP" ]; then
				/sbin/bridge fdb append to 00:00:00:00:00:00 dst "$remoteIP" dev vxlan0
				/sbin/bridge fdb append to "$(printf "02:47:89:00:%02x:00" "$remoteID" )" dst "$remoteIP" dev vxlan0
			else
				/sbin/bridge fdb append to "$(printf "02:47:89:00:%02x:00" "$ownID" )" dst 127.0.0.1 dev vxlan0
			fi
		fi
	done
}

# Remove all running vxlan tunnels
vxlan_stop() {
	/bin/ip link del vlan0
}
