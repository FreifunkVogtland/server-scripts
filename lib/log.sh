#!/bin/bash

log_add_msg() {
	local logDate=$(date "+%Y-%m-%d %H:%M:%S")
	logger "[FFC] $logDate $1"
}

log_warn() {
	log_add_msg "$1"
}

log_error() {
	log_add_msg "$1"
}

log_fatal_error() {
	echo "[FATAL] $1" >&2
	log_add_msg "$1"
	exit 1
}
