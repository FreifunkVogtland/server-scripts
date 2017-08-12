#!/bin/bash

vpn03_init() {
	if [ "$USE_BIRD" != "1" ]; then
		log_fatal_error "You must enable BIRD to use VPN03 - please check configuration!"
	fi
	iptables -w -A POSTROUTING -t nat -o $WANIF -s 10.204.0.0/16 -j MASQUERADE
	bird_add_route "0.0.0.0/0" "" "vpn03"
}

vpn03_start() {
	openvpn --config conf/vpn03.conf --daemon
}

vpn03_stop() {
	killall openvpn >> /dev/null 2>&1
}
