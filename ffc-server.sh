#!/bin/bash

. conf/general.conf
. conf/general.local.conf

. lib/log.sh
. lib/gre.sh
. lib/batman.sh
. lib/fastd.sh
. lib/bird.sh
. lib/dnsmasq.sh

# Set up network
ffc_start() {
	gre_init
	batman_init
	[ "$USE_FASTD" = "1" ] && fastd_init
	[ "$USE_BIRD" = "1" ] && bird_init
	[ "$USE_DNSMASQ" = "1" ] && dnsmasq_init
	
	gre_add_all_tunnels
	
	local running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		batman_add_interface "$i"
	done
	batman_setup_addresses
	
	[ "$USE_FASTD" = "1" ] && fastd_start
	[ "$USE_BIRD" = "1" ] && bird_start
	[ "$USE_DNSMASQ" = "1" ] && dnsmasq_start
}

# Destroy network
ffc_stop() {
	fastd_stop
	gre_stop
	batman_stop
	bird_stop
	dnsmasq_stop
}

# Perform status check
ffc_watchdog() {
	local running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		if [ $(gre_check_tunnel "$i") = 0 ]; then
			log_warn "GRE tunnel seems down: $i"
		fi
	done
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	watchdog) ffc_watchdog ;;
	*) echo "Usage: start | stop | watchdog" ;;
esac

exit 0
