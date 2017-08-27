#!/bin/bash

# Called by watchdog
dnsmasq_cron() {
	# read new hosts/ethers
	dns_pre="$(git -C /opt/freifunk/dns/ rev-parse HEAD)"
	git -C /opt/freifunk/dns/ pull -q
	dns_post="$(git -C /opt/freifunk/dns/ rev-parse HEAD)"

	if [ "${dns_pre}" != "${dns_post}" ]; then
		killall -SIGHUP dnsmasq
	fi
}
