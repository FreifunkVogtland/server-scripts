#!/bin/bash

batman_init() {
	modprobe batman-adv
	modprobe dummy
	batctl interface add dummy0
	batctl bridge_loop_avoidance 1
	batctl bonding 1
	[ "$USE_DNSMASQ" = "1" ] && batctl gw_mode server
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
	local macAddress=$(sed -e "s/^[a-z0-9]*:/02:/g" /sys/class/net/$WANIF/address)
	ip link set address $macAddress up dev bat0

	if [ -n "${ROUTERID}" ]; then
		ip addr add ${ROUTERID}/16 dev bat0
	fi

	for a in "${SERVICE_ADDRESSES[@]}"; do
		[ "$a" ] && ip addr add ${ROUTERID}/16 dev bat0
	done
	
	if [ "$USE_MESHVIEWER" != "1" ]; then
		batman_wait_for_ll_address
		alfred -i bat0 &> /dev/null &
		batadv-vis -s &> /dev/null &
	fi
}

batman_wait_for_ll_address() {
	local iface="bat0"
	local timeout=30

	for i in $(seq $timeout); do
		# We look for
		# - the link-local address (starts with fe80)
		# - without tentative flag (bit 0x40 in the flags field; the first char of the flags field begins 38 columns after the fe80 prefix
		# - on interface $iface
		if awk '
			BEGIN { RET=1 }
			/^fe80............................ .. .. .. [012389ab]./ { if ($6 == "'"$iface"'") RET=0 }
			END { exit RET }
		' /proc/net/if_inet6; then
			return
		fi
		sleep 1
	done
}

batman_stop() {
	rmmod batman-adv >> /dev/null 2>&1
}
