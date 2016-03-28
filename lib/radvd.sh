#!/bin/bash

radvd_init() {
	# TODO: Will be implemented in bird6.sh
	ip route add 2001:bc8:3f13:ffc2::/64 dev bat0
}

radvd_start() {
	radvd -C conf/radvd.conf
}

radvd_stop() {
	killall radvd >> /dev/null 2>&1
}
