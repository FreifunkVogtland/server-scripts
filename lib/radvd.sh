#!/bin/bash

radvd_start() {
	sleep 2
	sed -e "s/__BIRD_ROUTER_IDV6__/${ROUTERIDV6}/g" \
		conf/radvd.conf > conf/radvd.local.conf
	radvd -C conf/radvd.local.conf
}

radvd_stop() {
	killall radvd >> /dev/null 2>&1
}

# Called by watchdog
radvd_cron() {
	pidof radvd > /dev/null
	if [[ $? -ne 0 ]] ; then
		radvd_start
	fi
}
