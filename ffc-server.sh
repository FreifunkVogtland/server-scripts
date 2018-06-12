#!/bin/bash

PATH=$PATH:/usr/local/sbin/

# Set up network
ffc_start() {
	true
}

# Destroy network
ffc_stop() {
	true
}

case $1 in
	start) ffc_start ;;
	stop) ffc_stop ;;
	*) echo "Usage: start | stop" ;;
esac

exit 0
