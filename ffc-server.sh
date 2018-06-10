#!/bin/bash

PATH=$PATH:/usr/local/sbin/

. conf/general.conf
. conf/general.local.conf

. lib/bird.sh
. lib/bird6.sh
. lib/vxlan.sh

# Set up network
ffc_start() {
	ownid="$(vxlan_own_id)"
	if [ "$ownid" = "0" ]; then
		echo "Own WANIP not found in GRE_PEERS - please check configuration!"
		exit 1
	fi

	vxlan_init
	(bird_init ; bird6_init)
	
	vxlan_add_all_tunnels
	
	local running_ifnames=$(vxlan_get_running_ifnames)
	for i in $running_ifnames; do
		batctl interface add "$i"
		echo 1 > /sys/class/net/"$i"/batman_adv/no_rebroadcast
	done
}

# Destroy network
ffc_stop() {
	vxlan_stop

	while [ 1 ]; do
		ip rule delete lookup 100 >> /dev/null 2>&1
		if [ $? -gt 0 ]; then
			break
		fi
	done
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	*) echo "Usage: start | stop" ;;
esac

exit 0
