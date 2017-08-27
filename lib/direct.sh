#!/bin/bash

direct_init() {
	iptables -w -A POSTROUTING -t nat -o $WANIF -s 10.204.0.0/16 -j MASQUERADE
	# TODO promote default route via bird?
	# TODO use static route again towards direct gw
}
