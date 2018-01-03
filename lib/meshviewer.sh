#!/bin/bash

# Called by watchdog
meshviewer_cron() {
        /opt/freifunk/meshviewer/ffmap-backend/backend.py -d /opt/freifunk/meshviewer/data/ --prune 14 --with-graphite --graphite-metrics 'clients,loadavg,uptime' --with-graphite --graphite-metrics 'clients,loadavg,uptime,memory_usage,rootfs_usage,traffic.rx.bytes,traffic.tx.bytes,traffic.mgmt_tx.bytes,traffic.mgmt_rx.bytes,traffic.forward.bytes' --graphite-host localhost --graphite-prefix='freifunk.nodes.'

	# send global count to graphite
	/opt/freifunk/ffv-grafana-config/graphite-nodes.py /var/www/meshviewer/ffv/yanic/nodes.json|grep freifunk.global.offlinenodes|sed 's/freifunk\./freifunk2\./' | nc -q0 localhost 2003
	/opt/freifunk/ffv-grafana-config/graphite-nodes.py /var/www/meshviewer/ffv/yanic/nodes.json | nc -q0 localhost 2003
	/opt/freifunk/ffv-grafana-config/graphite-clients.py /var/www/meshviewer/ffv/yanic/nodes.json | nc -q0 localhost 2003

	# generate new files based on the json data
	/opt/freifunk/meshviewer/ffv-meshviewer-filter/filter.py /var/www/meshviewer/ffv/yanic/ /var/www/meshviewer/ffv/

	/opt/freifunk/meshviewer/ffv-nodes2eventlog/nodes2eventlog.py /var/www/meshviewer/ffv/nodes.json /opt/freifunk/meshviewer/ffv-nodes2eventlog/db /var/www/meshviewer/ffv/eventlog.atom
	OFFLINE_THRESHOLD=60 /opt/freifunk/meshviewer/ffv-nodes2eventlog/nodes2eventlog.py /var/www/meshviewer/ffv/nodes.json /opt/freifunk/meshviewer/ffv-nodes2eventlog/db-threshold60 /var/www/meshviewer/ffv/eventlog-threshold60.atom
	/opt/freifunk/meshviewer/ffv-nodes2eventlog/graveyard2rst.py /opt/freifunk/meshviewer/ffv-nodes2eventlog/db-threshold60 /var/www/meshviewer/ffv/graveyard.rst
	pandoc -f rst -t html5 -o /var/www/meshviewer/ffv/graveyard.html /var/www/meshviewer/ffv/graveyard.rst

	/opt/freifunk/ffv-api-generator/api-gen.py /var/www/meshviewer/ffv/nodelist.json /var/www/meshviewer/ffv/
	/opt/freifunk/meshviewer/nodelist2kml/nodelist2kml.py /var/www/meshviewer/ffv/nodelist.json /var/www/meshviewer/ffv/nodelist.kml

	/opt/freifunk/ffv-grafana-config/generate-dashboards.py  /var/www/meshviewer/ffv/nodelist.json /opt/freifunk/ffv-grafana-config/dashboard-templates/ /opt/freifunk/ffv-grafana-config/dashboard/dynamic/
}
