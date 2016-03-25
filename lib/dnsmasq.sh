#!/bin/bash

dnsmasq_init() {
	sed -e "s/__DNSMASQ_SERVICE_IP__/${SERVICE_ADDRESSES[0]}/g" \
		conf/dnsmasq.conf > conf/dnsmasq.local.conf
}

dnsmasq_start() {
	dnsmasq -C conf/dnsmasq.local.conf
}

dnsmasq_stop() {
	killall dnsmasq >> /dev/null 2>&1
}
