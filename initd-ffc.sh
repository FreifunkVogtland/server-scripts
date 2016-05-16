#!/bin/bash

### BEGIN INIT INFO
# Provides:		ffc
# Required-Start:	$all
# Required-Stop:	
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	Freifunk Server Scripts
### END INIT INFO


cd /opt/freifunk/server-scripts
./ffc-server.sh "$1"

exit 0
