#!/bin/bash

log_error() {
	local logDate=$(date "+%Y-%m-%d %H:%M:%S")
	logger "[FFC] $logDate $1"
}

log_fatal_error() {
	echo "[ERROR] $1" >&2
	log_error "$1"
	exit 1
}
