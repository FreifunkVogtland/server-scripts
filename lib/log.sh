#!/bin/bash

# Log message to syslog
#	$1		Message
log_add_msg() {
	local logDate=$(date "+%Y-%m-%d %H:%M:%S")
	logger "[FFC] $logDate $1"
}

# Log message to mail
#	$1		Message
log_add_mail() {
	local logDate=$(date "+%Y-%m-%d %H:%M:%S")
	mail -s "[FFC] Server Alert - $(hostname -f)" "crew@chemnitz.freifunk.net" <<EOF
$logDate

$1
EOF
}

# Log debug (if enabled)
#	$1		Message
log_debug() {
	[ "$LOG_DEBUG" = "1" ] && log_add_msg "$1"
}

# Log error
#	$1		Message
log_error() {
	log_add_msg "$1"
	[ "$IS_CRON" = "1" ] && log_add_mail "$1"
}

# Log fatal error and exit
#	$1		Message
log_fatal_error() {
	echo "[FATAL] $1" >&2
	log_add_msg "$1"
	[ "$IS_CRON" = "1" ] && log_add_mail "$1"
	exit 1
}
