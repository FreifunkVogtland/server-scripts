#!/bin/bash

PATH=$PATH:/usr/local/sbin/

. conf/general.conf
. conf/general.local.conf

. lib/log.sh
. lib/gre.sh
. lib/batman.sh
. lib/bird.sh
. lib/bird6.sh
. lib/dnsmasq.sh
. lib/direct.sh
. lib/meshviewer.sh

limit_throughput() {
    ip link delete ifb_uplink type ifb
    ip link add ifb_uplink type ifb
    ip link set ifb_uplink up
    
    tc qdisc del dev "${WANIF}" root
    tc qdisc add dev "${WANIF}" root handle 1: htb
    tc filter add dev "${WANIF}" parent 1:    protocol all u32 match u32 0 0 action mirred egress redirect dev ifb_uplink
    
    tc qdisc del dev "${WANIF}" ingress
    tc qdisc add dev "${WANIF}" handle ffff: ingress
    tc filter add dev "${WANIF}" parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev ifb_uplink
    
    tc qdisc del dev ifb_uplink root
    tc qdisc add dev ifb_uplink root handle 1: htb default 1
    tc class add dev ifb_uplink parent 1: classid 1:1 htb rate "${SHAPE_LIMIT}" ceil "${SHAPE_LIMIT}"
}

# Set up network
ffc_start() {
	ownid="$(gre_own_id)"
	if [ "$ownid" = "0" ]; then
		log_fatal_error "Own WANIP not found in GRE_PEERS - please check configuration!"
	fi

	[ ! -x /etc/rc.local.iptables ] || /etc/rc.local.iptables

	[ "$SHAPE_LIMIT" != "" ] && limit_throughput
	gre_init
	(bird_init ; bird6_init)
	[ "$USE_DIRECT" = "1" ] && direct_init
	
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
	[ "$USE_MESHVIEWER" = "1" ] && meshviewer_cron
	[ "$USE_DNSMASQ" = "1" ] &&  dnsmasq_cron
	
	# Every 5 minutes
	if [ $(($cronTime%300)) -lt 10 ]; then
		gre_cron
	fi
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	watchdog) ffc_watchdog ;;
	*) echo "Usage: start | stop | watchdog" ;;
esac

exit 0
