#!/bin/bash

fastd_init() {
	if [ ! -r "conf/fastd-secret.local.conf" ]; then
		log_fatal_error "Missing fastd-secret.local.conf - please check configuration!"
	fi
}

fastd_start() {
	touch conf/fastd.local.conf
	fastd -d -c conf/fastd0.conf
	fastd -d -c conf/fastd1.conf
	fastd -d -c conf/fastd2.conf
	fastd -d -c conf/fastd3.conf
}

fastd_stop() {
	killall fastd >> /dev/null 2>&1
}
