#!/bin/bash

PATH=$PATH:/usr/local/sbin/

. conf/general.conf
. conf/general.local.conf

. lib/bird.sh
. lib/bird6.sh

# Set up network
ffc_start() {
	(bird_init ; bird6_init)
}

# Destroy network
ffc_stop() {
	while [ 1 ]; do
		ip rule delete lookup 100 >> /dev/null 2>&1
		if [ $? -gt 0 ]; then
			break
		fi
	done
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	*) echo "Usage: start | stop" ;;
esac

exit 0
