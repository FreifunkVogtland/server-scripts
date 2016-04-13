#!/bin/bash

radvd_init() {
	if [ ! "$WANIF" ] || [ ! "$WANGW6" ]; then
		log_fatal_error "Missing WANIF or WANGW6 - please check configuration!"
	fi
	if [ "$USE_BIRD" != "1" ]; then
		log_fatal_error "You must enable BIRD to use RADVD - please check configuration!"
	fi
	bird6_add_route "::/0" "$WANGW6"
}

radvd_start() {
	sleep 2
	radvd -C conf/radvd.conf
}

radvd_stop() {
	killall radvd >> /dev/null 2>&1
}
