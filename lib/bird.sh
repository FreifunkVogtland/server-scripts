#!/bin/bash

bird_init() {
	ip rule add from 10.204.0.0/16 lookup 100
	ip rule add to 10.204.0.0/16 lookup 100
	ip rule add from 185.66.195.42/31 lookup 100
	ip rule add from 185.66.194.70/31 lookup 100
	ip rule add from all fwmark 0x1 table 100
	
	if [ -n "${BACKBONE_IPV4}" ]; then
		ip link add dev bb_ipv4 type dummy
		ip link set up dev bb_ipv4
		ip addr add "${BACKBONE_IPV4}" dev bb_ipv4
	fi
}
