#!/bin/bash

batman_init() {
	modprobe batman-adv
	modprobe dummy
	batctl interface add dummy0
	batctl gw_mode client
	batctl bridge_loop_avoidance 1
	batctl bonding 1
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

batman_stop() {
	rmmod batman-adv >> /dev/null 2>&1
}
