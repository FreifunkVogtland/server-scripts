#!/bin/bash

. conf/general.conf
. conf/general.local.conf

. sbin/log.sh
. sbin/gre.sh
. sbin/batman.sh
. sbin/bird.sh

# Init network (run in rc.d)
start() {
	gre_init
	gre_add_all_tunnels
}

exit 0
