# server-scripts

The server scripts are deployed using ansible-configs.

### Selection of services

* on gateways:
  - USE_FASTD
  - USE_BIRD
* on gateways with address distribution
  - USE_FASTD
  - USE_BIRD
  - USE_DNSMASQ
* uplink servers
  - USE_BIRD
* on meshviewer server
  - USE_MESHVIEWER

### WAN settings

* SERVICE_ADDRESSES
  - has to be obtained from the manager of the IP address space
* WANGW
  - set it to the next hop for IPv4 traffic towards the native uplink
* WANGW6
  - set it to the next hop for IPv6 traffic towards the native uplink
* WANIF
  - set it to the interface pointing towards the native uplink

### GRE Peers

* adjust GRE_PEERS to include all peers including itself with $WANIP
* update server scripts on other servers to add new entry


### fastd

* create key via `fastd --generate-key`
  - save secret key to `conf/fastd-secret.local.conf` as `secret "123456789";`
* get public key from conf/fastd-secret.local.conf and add new entry to site-ffc.git/site.conf
  - public key can recreated from secret key via `fastd --show-key -c conf/fastd.conf`

### Logging

Change MAIL_TO in `lib/log.sh` to send reports to the server admin. Requires working sendmail

## IC-VPN

Required packages:

* tinc
* python3-yaml

Required BIRD to be enabled and explanations for installation can be found
under https://wiki.freifunk.net/IC-VPN

We clone our icvpn scripts in /opt/freifunk/icvpn-scripts. The generated bgp
peer configs have to be stored in

 * /var/tmp/bird-icvpn.conf
 * /var/tmp/bird6-icvpn.conf

Also the mkbgp option "-d" has to be changed from peers to icvpn following
is the part of the cron script which writes the peers

    /opt/freifunk/icvpn-scripts/mkbgp -x vogtland -p icvpn_ -f bird  -d icvpn -s "$DATADIR" -4 > /var/tmp/bird-icvpn.conf
    birdc configure > /dev/null
    /opt/freifunk/icvpn-scripts/mkbgp -x vogtland -p icvpn_ -f bird  -d icvpn -s "$DATADIR" -6 > /var/tmp/bird6-icvpn.conf
    birdc6 configure > /dev/null

For DNS the dnsmasq config has to be created

    /opt/freifunk/icvpn-scripts/mkdns -s "$DATADIR" -x vogtland -f dnsmasq > /var/tmp/dnsmasq-icvpn.conf
    
TODO automatically restart dnsmasq on dnsmasq-icvpn.conf changes
