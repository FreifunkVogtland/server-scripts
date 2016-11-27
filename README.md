# server-scripts

## Extra repositories

    deb     http://httpredir.debian.org/debian/ jessie-backports main contrib non-free

## Required packages (Debian Jessie)

* alfred
* cron
* dnsmasq
* radvd
* bird
* bird6
* openvpn
* iproute2
* batctl
* linux-headers-$arch
* build-essential
* fastd
* git
* procps
* iptables
* rsyslog
* python3
* ethtool
* $MAIL_SERVER

For meshviewer:

* rrdtool
* python3-xe
* python3-feed
* jq
* python3-networkx
* alfred-json
* python3-dateutil
* nc

The vpn interface stats also require:

* libapache2-mod-php5
* vnstati

IC-VPN

* tinc
* python3-yaml

## Startup workarounds

Some packages try to start automatically via their own init scripts. These
have to be disabled manually to avoid conflicts with the processes started
by the initd-ffc.sh script. The system (Debian Jessie) is by default shipped
with systemd and thus the systemctl utility is used to modify the startup
process

    systemctl disable dnsmasq.service
    systemctl disable bird
    systemctl disable bird6

## Checkout of the repository

    mkdir -p /opt/freifunk/
    git clone https://github.com/FreifunkVogtland/server-scripts.git /opt/freifunk/server-scripts
    ln -s /opt/freifunk/server-scripts/initd-ffc.sh /etc/init.d/ffc
    systemctl enable ffc
    echo 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' > /etc/cron.d/ffc
    echo '* * * * *   root /opt/freifunk/server-scripts/initd-ffc.sh watchdog' >> /etc/cron.d/ffc
    git clone https://github.com/FreifunkVogtland/dns-static.git /opt/freifunk/dns

## Extra configuration in /etc

    echo '100     freifunk' >> /etc/iproute2/rt_tables

## Build of batman-adv

    git clone -b maint git://git.open-mesh.org/batman-adv.git /usr/src/batman-adv
    git -C /usr/src/batman-adv am /opt/freifunk/server-scripts/patches/batman-adv/*.patch
    make -C /usr/src/batman-adv
    make -C /usr/src/batman-adv install

## Alfred Announce

    git clone https://github.com/ffnord/ffnord-alfred-announce  /opt/freifunk/ffnord-alfred-announce
    git -C /opt/freifunk/ffnord-alfred-announce am /opt/freifunk/server-scripts/patches/ffnord-announce/*.patch
    cp respondd.service /etc/systemd/system/
    echo '* * * * *   root /opt/freifunk/ffnord-alfred-announce/announce.sh' >> /etc/cron.d/ffc
    systemctl daemon-reload
    systemctl start respondd.service
    systemctl enable respondd

## Configuration

* create new copy of `conf/general.conf` called `conf/general.local.conf`
* remove GRE_PEERS from `conf/general.local.conf`

### Selection of services

* on gateways:
  - USE_FASTD
  - USE_BIRD
* on gateways with address distribution
  - USE_FASTD
  - USE_BIRD
  - USE_DNSMASQ
  - USE_RADVD
* uplink servers
  - USE_VPN03
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

### native uplink settings

Some address ranges can be used directly from the VPN without going through
a server in another country. A list of these IP ranges in managed by the FFC
API and following entries have to be added to the general.local.conf

* COUNTRY
  - usually "DE"
* APIKEY
  - key to access the API - can be requested from Steffen

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

### VPN03

A secret key has to be registered via https://wiki.freifunk.net/Vpn03

Save secret key for FFB VPN03 under `conf/vpn03.local.key`

### Traffic statistics

    # be careful - this is just for an "empty" /var/www/html
    git clone https://github.com/ambassador86/ffc-server-statistics.git /var/www/vnstat
    ln -s /var/www/vnstat/index.php /var/www/html/index.php
    ln -s /var/www/vnstat/stats.conf /var/www/html/stats.conf
    echo '* *     * * *   root    /var/www/vnstat/vnstat.sh' >> /etc/cron.d/ffc
    # now adjust interfaces (usually "eth0 fastd-mesh") and wwwroot (usually "/var/www/html"
    vi /var/www/vnstat/stats.conf

### Meshviewer

    mkdir -p /opt/freifunk/meshviewer/data/nodedb /var/www/meshviewer/ffv/
    git clone https://github.com/FreifunkVogtland/ffv-api-generator.git /opt/freifunk/ffv-api-generator
    git clone https://github.com/FreifunkVogtland/ffv-meshviewer-filter.git /opt/freifunk/meshviewer/ffv-meshviewer-filter
    git clone https://github.com/FreifunkVogtland/nodes2eventlog.git /opt/freifunk/meshviewer/ffv-nodes2eventlog
    git clone https://github.com/ffnord/ffmap-backend.git /opt/freifunk/meshviewer/ffmap-backend -b dev
    git -C /opt/freifunk/meshviewer/ffmap-backend am /opt/freifunk/server-scripts/patches/ffmap-backend/*.patch
    touch /opt/freifunk/meshviewer/ffmap-backend/alias.json
    mkdir -p /opt/freifunk/meshviewer/ffv-nodes2eventlog/db
    # read /opt/freifunk/meshviewer/ffv-meshviewer-filter/globalrrd.py for info how to create /opt/freifunk/meshviewer/ffv-meshviewer-filter/nodedb/

## IC-VPN

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
