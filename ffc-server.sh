#!/bin/bash

PATH=$PATH:/usr/local/sbin/

. conf/general.conf
. conf/general.local.conf

. lib/log.sh
. lib/gre.sh
. lib/batman.sh
. lib/fastd.sh
. lib/bird.sh
. lib/bird6.sh
. lib/dnsmasq.sh
. lib/radvd.sh
. lib/vpn03.sh
. lib/meshviewer.sh

# Set up network
ffc_start() {
	ownid="$(gre_own_id)"
	if [ "$ownid" = "0" ]; then
		log_fatal_error "Own WANIP not found in GRE_PEERS - please check configuration!"
	fi

	gre_init
	batman_init
	[ "$USE_FASTD" = "1" ] && fastd_init
	[ "$USE_BIRD" = "1" ] && (bird_init ; bird6_init)
	[ "$USE_DNSMASQ" = "1" ] && dnsmasq_init
	[ "$USE_VPN03" = "1" ] && vpn03_init
	
	gre_add_all_tunnels
	
	local running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		batman_add_interface "$i"
		echo 1 > /sys/class/net/"$i"/batman_adv/no_rebroadcast
	done
	batman_setup_interface
	
	[ "$USE_FASTD" = "1" ] && fastd_start
	[ "$USE_BIRD" = "1" ] && (bird_start ; bird6_start)
	[ "$USE_DNSMASQ" = "1" ] && dnsmasq_start
	[ "$USE_RADVD" = "1" ] && radvd_start
	[ "$USE_VPN03" = "1" ] && vpn03_start
	
	sysctl -p conf/sysctl.conf >> /dev/null 2>&1
}

# Destroy network
ffc_stop() {
	fastd_stop
	gre_stop
	batman_stop
	bird_stop
	bird6_stop
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

# Run every minute by cron.d
ffc_watchdog() {
	export IS_CRON="1"
	local cronTime=$(date +%s)
	
	# Every minute
	[ "$USE_MESHVIEWER" = "1" ] && meshviewer_cron
	[ "$USE_RADVD" = "1" ] &&  radvd_cron
	[ "$USE_DNSMASQ" = "1" ] &&  dnsmasq_cron
	
	# Every 5 minutes
	if [ $(($cronTime%300)) -lt 10 ]; then
		gre_cron
		[ "$USE_BIRD" = "1" ] && bird_cron
	fi
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	watchdog) ffc_watchdog ;;
	*) echo "Usage: start | stop | watchdog" ;;
esac

exit 0
