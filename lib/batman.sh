#!/bin/bash

batman_init() {
	modprobe batman-adv
	modprobe dummy
	batctl interface add dummy0
	batctl bridge_loop_avoidance 1
	batctl bonding 1
	[ "$USE_DNSMASQ" = "1" ] && batctl gw_mode server
	alfred -m -i bat0 &> /dev/null &
}

# Add interface to batman-adv
#	$1		Interface name
batman_add_interface() {
	batctl interface add $1
}

# Remove interface from batman-adv
#	$1		Interface name
batman_del_interface() {
	batctl interface del $1 >> /dev/null 2>&1
}

batman_setup_interface() {
	for a in "${SERVICE_ADDRESSES[@]}"; do
		[ "$a" ] && ip addr add $a dev bat0
	done
	ip link set up dev bat0
}

batman_stop() {
	killall alfred >> /dev/null 2>&1
	rmmod batman-adv >> /dev/null 2>&1
}
