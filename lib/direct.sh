#!/bin/bash

direct_init() {
	if [ "$USE_BIRD" != "1" ]; then
		log_fatal_error "You must enable BIRD to use DIRECT - please check configuration!"
	fi
	iptables -w -A POSTROUTING -t nat -o $WANIF -s 10.204.0.0/16 -j MASQUERADE
	# promote default route via bird?
}
