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
        /opt/freifunk/meshviewer/ffmap-backend/backend.py -d /opt/freifunk/meshviewer/data/ --rrd-path /opt/freifunk/meshviewer/data/nodedb --with-rrd --prune 30

	# TODO
	/opt/freifunk/meshviewer/ffv-meshviewer-filter/filter.py /opt/freifunk/meshviewer/data/ /var/www/meshviewer/ffv/

	/opt/freifunk/meshviewer/ffv-meshviewer-filter/globalrrd.py /var/www/meshviewer/ffv/ /opt/freifunk/meshviewer/ffv-meshviewer-filter/nodedb/
	/opt/freifunk/meshviewer/ffv-meshviewer-filter/globalGraph.sh /opt/freifunk/meshviewer/ffv-meshviewer-filter/nodedb/nodes.rrd /var/www/meshviewer/ffv/globalGraph.png

	/opt/freifunk/meshviewer/ffv-nodes2eventlog/nodes2eventlog.py /var/www/meshviewer/ffv/nodes.json /opt/freifunk/meshviewer/ffv-nodes2eventlog/db /var/www/meshviewer/ffv/eventlog.atom
	OFFLINE_THRESHOLD=60 /opt/freifunk/meshviewer/ffv-nodes2eventlog/nodes2eventlog.py /var/www/meshviewer/ffv/nodes.json /opt/freifunk/meshviewer/ffv-nodes2eventlog/db-threshold60 /var/www/meshviewer/ffv/eventlog-threshold60.atom

	/opt/freifunk/ffv-api-generator/api-gen.py /var/www/meshviewer/ffv/nodelist.json /var/www/meshviewer/ffv/
}

meshviewer_stop() {
	killall alfred >> /dev/null 2>&1
}
