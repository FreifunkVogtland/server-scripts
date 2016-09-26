#!/bin/bash

batman_init() {
	modprobe batman-adv
	modprobe dummy
	ip link add name dummy1 type dummy
	batctl -m bat0 interface add dummy0
	batctl -m bat1 interface add dummy1
	batctl -m bat0 bridge_loop_avoidance 1
	batctl -m bat1 bridge_loop_avoidance 1
	batctl -m bat0 bonding 1
	batctl -m bat1 bonding 1
	brctl addbr br-ff
	brctl addif br-ff bat0
	brctl addif br-ff bat1
	ip addr add 2001:bc8:3f13:ffc2:250:56ff:febd:6c6e/64 dev br-ff
	[ "$USE_DNSMASQ" = "1" ] && batctl -m bat0 gw_mode server
}

# Add interface to batman-adv
#	$1		Interface name
batman_add_interface() {
	if [[ $1 == gre-ffv* ]]; then
		batctl -m bat0 interface add $1
	else
		batctl -m bat0 interface add $1
		#batctl -m bat1 interface add $1
	fi
}

# Remove interface from batman-adv
#	$1		Interface name
batman_del_interface() {
	if [[ $1 == gre-ffv* ]]; then
		batctl -m bat0 interface del $1 >> /dev/null 2>&1
	else
		batctl -m bat0 interface del $1 >> /dev/null 2>&1
		#batctl -m bat1 interface del $1 >> /dev/null 2>&1
	fi
}

batman_setup_interface() {
	local macAddress=$(sed -e "s/^[a-z0-9]*:/02:/g" /sys/class/net/$WANIF/address)
	ip link set address $macAddress up dev br-ff
	ip link set  up dev bat0
	ip link set  up dev bat1
	for a in "${SERVICE_ADDRESSES[@]}"; do
		[ "$a" ] && ip addr add $a dev br-ff
	done
	
	if [ "$USE_MESHVIEWER" != "1" ]; then
		batman_wait_for_ll_address
		alfred -i br-ff -b bat1 &> /dev/null &
		batadv-vis -s &> /dev/null &
	fi
}

batman_wait_for_ll_address() {
	local iface="br-ff"
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
