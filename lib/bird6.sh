#!/bin/bash

bird6_init() {
	ip -6 rule add from 2a03:2260:200f::/48 lookup 100
	ip -6 rule add to 2a03:2260:200f::/48 lookup 100
	ip -6 rule add from all fwmark 0x1 lookup 100
	ip -6 rule add from all lookup 100 priority 32767
}
