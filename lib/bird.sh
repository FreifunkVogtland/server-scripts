#!/bin/bash

bird_init() {
	local ipL1=$(echo $WANIP | awk -F '.' '{print $3}')
	local ipL2=$(echo $WANIP | awk -F '.' '{print $4}')
	sed -e "s/__BIRD_ROUTER_ID__/${ROUTERID}/g" \
		-e "s/__BIRD_ROUTER_IP__/169.254.${ipL1}.${ipL2}/g" \
		-e "s/__BIRD_ROUTER_ASN__/${OWNASN}/g" \
		conf/bird.conf > conf/bird.local.conf
	
	echo -n "" > conf/bird-peers.local.conf
	for p in "${GRE_PEERS[@]}"; do
		local remoteHost=$(echo $p | awk -F ':' '{print $1}')
		local remoteID=$(echo $p | awk -F ':' '{print $2}')
		local remoteIP=$(echo $p | awk -F ':' '{print $3}')
		if [ "$remoteHost" ] && [ "$remoteIP" ]; then
			# Do not add ourselves as a peer
			if [ "$remoteIP" != "$WANIP" ]; then
				bird_add_peer "${remoteHost}" "$remoteID"
			fi
		else
			log_error "Syntax error in peer definition: ${p}"
		fi
	done
	
	echo -n "" > conf/bird-routes.local.conf
	for s in "${SERVICE_ADDRESSES[@]}"; do
		if [ "$(bird_check_route "$s")" ]; then
			bird_add_route "$s"
		fi
	done

	touch conf/bird-routes.country.conf

	ip rule add from 10.204.0.0/16 lookup 100
	ip rule add to 10.204.0.0/16 lookup 100
	ip route add default via 127.0.0.1 table 100 metric 1024
	
	iptables -t nat -A POSTROUTING -o $WANIF -j MASQUERADE
	iptables -t mangle -A FORWARD -o bb-+ -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1240 -j TCPMSS --set-mss 1240
	iptables -t mangle -A FORWARD -o bat0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1240 -j TCPMSS --set-mss 1240

	touch /var/tmp/bird-icvpn.conf conf/bird.ffrl.conf
	echo "" > conf/bird-hostroute.local.conf
	if [ -n "${BACKBONE_IPV4}" ]; then
		echo "if net ~ ${BACKBONE_IPV4} then accept;" >> conf/bird-hostroute.local.conf
		ip addr add "${BACKBONE_IPV4}" dev lo
		iptables -t nat -A POSTROUTING -o bb-+ -j SNAT --to-source "$(echo "${BACKBONE_IPV4}"|sed 's/\/.*$//')"
		ip rule add from ${BACKBONE_IPV4} lookup 100
	fi
}

# Check for route
#	$1		IPv4 route
bird_check_route() {
	[[ "$1" =~ ^[0-9.]*/[0-9]+ ]] && echo "1"
}

bird_start() {
	mkdir /run/bird
	bird -c conf/bird.local.conf
}

bird_stop() {
	killall bird >> /dev/null 2>&1
}

bird_cron() {
	if [ -n $WANGW -a -n $APIKEY ]; then
		wget "http://api.routers.chemnitz.freifunk.net/request.php?apikey=$APIKEY&type=routing&region=$COUNTRY" -q -O conf/bird-routes.country.conf
		sed -e "s/NEXTHOP/$WANGW/g" -i "conf/bird-routes.country.conf"
		killall bird -s SIGHUP
	fi
}

# Add BGP peer
# 	$1		Hostname
# 	$2		Peer ID
bird_add_peer() {
	local ipP1="$(($2 << 4))"
	sed -e "s/__BIRD_REMOTE_HOST__/$1/g" \
		-e "s/__BIRD_REMOTE_IP__/10.204.${ipP1}.1/g" \
		-e "s/__BIRD_REMOTE_ASN__/${OWNASN}/g" \
		conf/bird-peers.conf >> conf/bird-peers.local.conf
}

# Add BGP route
# 	$1		IPv4 Route
#	$2		Next hop (optional)
#	$3		Next hop interface (optional)
bird_add_route() {
	local via="\"bat0\""
	[ "$2" ] && local via="$2"
	[ "$3" ] && local via="\"$3\""
	sed -e "s|__BIRD_ROUTE__|$1|g" \
		-e "s/__BIRD_VIA__/$via/g" \
		conf/bird-routes.conf >> conf/bird-routes.local.conf
}
