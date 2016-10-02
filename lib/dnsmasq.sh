#!/bin/bash

dnsmasq_init() {
	if [ ! -n "${ROUTERID}" ]; then
		log_fatal_error "Missing ROUTERID address for DHCP - please check configuration!"
	fi

	sed -e "s/__DNSMASQ_SERVICE_IP__/${ROUTERID}/g" \
		-e "s/__DNSMASQ_RANGE__/${DNSMASQ_RANGE}/g" \
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
