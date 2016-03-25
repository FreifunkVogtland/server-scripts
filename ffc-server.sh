#!/bin/bash

. conf/general.conf
. conf/general.local.conf

. sbin/log.sh
. sbin/gre.sh
. sbin/batman.sh
. sbin/fastd.sh
. sbin/bird.sh

# Set up network
ffc_start() {
	gre_init
	gre_add_all_tunnels
	
	batman_init
	local running_ifnames=$(gre_get_running_ifnames)
	for i in $running_ifnames; do
		batman_add_interface "$i"
	done
	
	if [ "$USE_FASTD" = "1" ]; then
		fastd_init
		fastd_start
	fi
}

# Destroy network
ffc_stop() {
	gre_del_all_tunnels
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	status) ffc_status ;;
	*) echo "Usage: start | stop" ;;
esac

exit 0
