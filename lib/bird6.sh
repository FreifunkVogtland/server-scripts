#!/bin/bash

bird6_init() {
	ip -6 rule add from 2a03:2260:200f::/48 lookup 100
	ip -6 rule add to 2a03:2260:200f::/48 lookup 100
	ip -6 rule add from all fwmark 0x1 lookup 100
	ip -6 rule add from all lookup 100 priority 32767

	ip6tables -t mangle -A FORWARD -o bb-+ -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1220 -j TCPMSS --set-mss 1220
	ip6tables -t mangle -A FORWARD -o bat0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss ! --mss 0:1220 -j TCPMSS --set-mss 1220

	ip6tables -t mangle -A PREROUTING -i bat+ -j MARK --set-xmark 0x1/0xffffffff
	ip6tables -t mangle -A PREROUTING -i icvpn -j MARK --set-xmark 0x1/0xffffffff

	touch conf/bird6.ffrl.conf
}

bird6_start() {
	true
}

bird6_stop() {
	true
}

