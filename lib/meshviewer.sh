#!/bin/bash

meshviewer_init() {
	if [ "$USE_MESHVIEWER" = "1" ]; then
		sleep 2
		alfred -m -i bat0 &> /dev/null &
	fi
}

# Called by watchdog
meshviewer_cron() {
        local cronTime=$(date +%s)

        if [ $(($cronTime%1800)) -lt 10 ]; then
                # every 30 min with image creation
                /opt/freifunk/meshviewer/ffmap-backend/backend.py -d /opt/freifunk/meshviewer/data/ --rrd-path /opt/freifunk/meshviewer/data/nodedb --with-rrd --with-img
        else
                /opt/freifunk/meshviewer/ffmap-backend/backend.py -d /opt/freifunk/meshviewer/data/ --rrd-path /opt/freifunk/meshviewer/data/nodedb --with-rrd
        fi
	jq -c '.nodes = (.nodes | map(del(.value.nodeinfo.owner)))' < /opt/freifunk/meshviewer/data/nodes.json > /opt/freifunk/meshviewer/data/nodes.json.priv
}

meshviewer_stop() {
	killall alfred >> /dev/null 2>&1
}
