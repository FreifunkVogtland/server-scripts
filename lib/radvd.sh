#!/bin/bash

radvd_start() {
	sleep 2
	radvd -C conf/radvd.conf
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
