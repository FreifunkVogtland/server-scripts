#!/bin/bash

. conf/general.conf
. conf/general.local.conf

. sbin/log.sh
. sbin/gre.sh
. sbin/batman.sh
. sbin/bird.sh

# Init network (run in rc.d)
ffc_start() {
	gre_init
	gre_add_all_tunnels
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	*) echo "Usage: start | stop" ;;
esac

exit 0
