#!/bin/bash

bird_init() {
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

	touch conf/bird.ffrl.conf
	if [ -n "${BACKBONE_IPV4}" ]; then
		ip addr add "${BACKBONE_IPV4}" dev lo
		iptables -w -t nat -A POSTROUTING -o bb-+ -j SNAT --to-source "$(echo "${BACKBONE_IPV4}"|sed 's/\/.*$//')"
	fi
}
