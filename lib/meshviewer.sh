#!/bin/bash

meshviewer_init() {
	if [ "$USE_MESHVIEWER" = "1" ]; then
		batman_wait_for_ll_address
		alfred -m -i bat0 &> /dev/null &
		batadv-vis -s &> /dev/null &
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

        jq -c '.nodes = (.nodes | map(del(.value.nodeinfo.owner)))' < /opt/freifunk/meshviewer/data/nodes.json > /opt/freifunk/meshviewer/data/nodes.json.priv.tmp
        if json_pp < /opt/freifunk/meshviewer/data/nodes.json.priv.tmp >& /dev/null; then
                mv /opt/freifunk/meshviewer/data/nodes.json.priv.tmp /opt/freifunk/meshviewer/data/nodes.json.priv
        fi
}

meshviewer_stop() {
	killall alfred >> /dev/null 2>&1
}
