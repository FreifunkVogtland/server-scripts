#!/bin/bash

bird6_init() {
	sed -e "s/__BIRD_ROUTER_ID__/${ROUTERID}/g" \
		-e "s/__BIRD_ROUTER_ASN__/${OWNASN}/g" \
		conf/bird6.conf > conf/bird6.local.conf
	
	echo -n "" > conf/bird6-peers.local.conf
	for p in "${GRE_PEERS[@]}"; do
		local remoteHost=$(echo $p | awk -F ':' '{print $1}')
		local remoteID=$(echo $p | awk -F ':' '{print $2}')
		local remoteIP=$(echo $p | awk -F ':' '{print $3}')
		if [ "$remoteHost" ] && [ "$remoteIP" ]; then
			# Do not add ourselves as a peer
			if [ "$remoteIP" != "$WANIP" ]; then
				bird6_add_peer "${remoteHost}" "$remoteID"
			fi
		else
			log_error "Syntax error in peer definition: ${p}"
		fi
	done
	
	echo -n "" > conf/bird6-routes.local.conf
	for s in "${SERVICE_ADDRESSES[@]}"; do
		if [ "$(bird6_check_route "$s")" ]; then
			bird6_add_route "$s"
		fi
	done
	
	ip -6 rule add from 2a03:2260:200f::/48 lookup 100
	ip -6 rule add to 2a03:2260:200f::/48 lookup 100
	ip -6 rule add from all fwmark 0x1 lookup 100
	ip -6 rule add from all lookup 100 priority 32767

	ip6tables -t mangle -A FORWARD -o bb-+ -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1220 -j TCPMSS --set-mss 1220
	ip6tables -t mangle -A FORWARD -o bat0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1220 -j TCPMSS --set-mss 1220

	ip6tables -t mangle -A PREROUTING -i bat+ -j MARK --set-xmark 0x1/0xffffffff
	ip6tables -t mangle -A PREROUTING -i icvpn -j MARK --set-xmark 0x1/0xffffffff

	touch /var/tmp/bird6-icvpn.conf conf/bird6.ffrl.conf
}

# Check for route
#	$1		IPv6 route
bird6_check_route() {
	[[ "$1" =~ ^[a-f0-9:]*/[0-9]+ ]] && echo "1"
}

bird6_start() {
	bird6 -c conf/bird6.local.conf
}

bird6_stop() {
	killall bird6 >> /dev/null 2>&1
}

# Add BGP peer
# 	$1		Hostname
# 	$2		Peer ID
bird6_add_peer() {
	local ipP1="$2"
	sed -e "s/__BIRD_REMOTE_HOST__/$1/g" \
		-e "s/__BIRD_REMOTE_IP__/2a03:2260:200f:1337::${ipP1}/g" \
		-e "s/__BIRD_REMOTE_ASN__/${OWNASN}/g" \
		conf/bird-peers.conf >> conf/bird6-peers.local.conf
}

# Add BGP route
# 	$1		IPv6 Route
#	$2		Next hop (optional)
#	$3		Next hop interface (mandatory, if $2 is selected)
bird6_add_route() {
	local via="\"bat0\""
	if [ "$2" ] && [ "$3" ]; then
		local via="$2 % $3"
	fi
	sed -e "s|__BIRD_ROUTE__|$1|g" \
		-e "s/__BIRD_VIA__/$via/g" \
		conf/bird-routes.conf >> conf/bird6-routes.local.conf
}
