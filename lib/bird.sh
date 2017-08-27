#!/bin/bash

bird_init() {
	sed -e "s/__BIRD_ROUTER_ID__/${ROUTERID}/g" \
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

	ip rule add from 10.204.0.0/16 lookup 100
	ip rule add to 10.204.0.0/16 lookup 100
	ip rule add from 185.66.195.42/31 lookup 100
	ip rule add from 185.66.194.70/31 lookup 100
	ip rule add from all fwmark 0x1 table 100
	ip route add default via 127.0.0.1 table 100 metric 1024
	
	iptables -w -t nat -A POSTROUTING -o $WANIF -j MASQUERADE
	iptables -w -t mangle -A FORWARD -o bb-+ -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1240 -j TCPMSS --set-mss 1240
	iptables -w -t mangle -A FORWARD -o bat0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1240 -j TCPMSS --set-mss 1240

	iptables -w -t mangle -A PREROUTING -i bat+ -j MARK --set-xmark 0x1/0xffffffff
	iptables -w -t mangle -A PREROUTING -i icvpn -j MARK --set-xmark 0x1/0xffffffff

	touch /var/tmp/bird-icvpn.conf conf/bird.ffrl.conf
	echo "" > conf/bird-hostroute.local.conf
	if [ -n "${BACKBONE_IPV4}" ]; then
		echo "if net ~ ${BACKBONE_IPV4} then accept;" >> conf/bird-hostroute.local.conf
		ip addr add "${BACKBONE_IPV4}" dev lo
		iptables -w -t nat -A POSTROUTING -o bb-+ -j SNAT --to-source "$(echo "${BACKBONE_IPV4}"|sed 's/\/.*$//')"
	fi
}

bird_start() {
	mkdir /run/bird
	bird -c conf/bird.local.conf
}

bird_stop() {
	killall bird >> /dev/null 2>&1
}

bird_cron() {
	true
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
