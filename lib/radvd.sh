#!/bin/bash

radvd_init() {
	[ "$USE_BIRD" = "1" ] && bird6_add_route "::/0"
}

radvd_start() {
	sleep 2
	radvd -C conf/radvd.conf
}

radvd_stop() {
	killall radvd >> /dev/null 2>&1
}
