#!/bin/bash

PATH=$PATH:/usr/local/sbin/

. conf/general.conf
. conf/general.local.conf

. lib/gre.sh
. lib/batman.sh
. lib/bird.sh
. lib/bird6.sh
. lib/dnsmasq.sh

# Set up network
ffc_start() {
	ownid="$(gre_own_id)"
	if [ "$ownid" = "0" ]; then
		echo "Own WANIP not found in GRE_PEERS - please check configuration!"
		exit 1
	fi

	gre_init
	(bird_init ; bird6_init)
	
	gre_add_all_tunnels
	
	local running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		batman_add_interface "$i"
		echo 1 > /sys/class/net/"$i"/batman_adv/no_rebroadcast
	done
}

# Destroy network
ffc_stop() {
	gre_stop

	while [ 1 ]; do
		ip rule delete lookup 100 >> /dev/null 2>&1
		if [ $? -gt 0 ]; then
			break
		fi
	done
}

# Run every minute by cron.d
ffc_watchdog() {
	export IS_CRON="1"
	local cronTime=$(date +%s)
	
	# Every minute
	[ "$USE_DNSMASQ" = "1" ] &&  dnsmasq_cron
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	watchdog) ffc_watchdog ;;
	*) echo "Usage: start | stop | watchdog" ;;
esac

exit 0
