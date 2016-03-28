#!/bin/bash

. conf/general.conf
. conf/general.local.conf

. lib/log.sh
. lib/gre.sh
. lib/batman.sh
. lib/fastd.sh
. lib/bird.sh
. lib/dnsmasq.sh
. lib/radvd.sh
. lib/vpn03.sh

# Set up network
ffc_start() {
	gre_init
	batman_init
	[ "$USE_FASTD" = "1" ] && fastd_init
	[ "$USE_BIRD" = "1" ] && bird_init
	[ "$USE_DNSMASQ" = "1" ] && dnsmasq_init
	[ "$USE_RADVD" = "1" ] && radvd_init
	[ "$USE_VPN03" = "1" ] && vpn03_init
	
	gre_add_all_tunnels
	
	local running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		batman_add_interface "$i"
	done
	batman_setup_interface
	
	[ "$USE_FASTD" = "1" ] && fastd_start
	[ "$USE_BIRD" = "1" ] && bird_start
	[ "$USE_DNSMASQ" = "1" ] && dnsmasq_start
	[ "$USE_RADVD" = "1" ] && radvd_start
	[ "$USE_VPN03" = "1" ] && vpn03_start

	ip rule add from 10.149.0.0/16 lookup 100
	ip rule add to 10.149.0.0/16 lookup 100	
	sysctl -p conf/sysctl.conf >> /dev/null 2>&1
}

# Destroy network
ffc_stop() {
	fastd_stop
	gre_stop
	batman_stop
	bird_stop
	dnsmasq_stop
	radvd_stop
	vpn03_stop
	
	while [ 1 ]; do
		ip rule delete lookup 100 >> /dev/null 2>&1
		if [ $? -gt 0 ]; then
			break
		fi
	done
}

# Perform status check
ffc_watchdog() {
	local running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		if [ ! "$(gre_check_tunnel "$i")" ]; then
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
