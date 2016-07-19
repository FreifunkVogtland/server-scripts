#!/bin/bash

dnsmasq_init() {
	if [ ! "${SERVICE_ADDRESSES[0]}" ]; then
		log_fatal_error "Missing DHCP service address - please check configuration!"
	fi
	sed -e "s/__DNSMASQ_SERVICE_IP__/${SERVICE_ADDRESSES[0]}/g" \
		conf/dnsmasq.conf > conf/dnsmasq.local.conf
}

dnsmasq_start() {
	dnsmasq -C conf/dnsmasq.local.conf
}

dnsmasq_stop() {
	killall dnsmasq >> /dev/null 2>&1
}

# Called by watchdog
dnsmasq_cron() {
	pidof dnsmasq > /dev/null
	if [[ $? -ne 0 ]] ; then
		dnsmasq_start
	fi
}
