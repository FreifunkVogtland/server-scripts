# server-scripts

The server scripts are deployed using ansible-configs.

### WAN settings

* WANIF
  - set it to the interface pointing towards the native uplink

### GRE Peers

* adjust GRE_PEERS to include all peers including itself with $WANIP
* update server scripts on other servers to add new entry


### Logging

Change MAIL_TO in `lib/log.sh` to send reports to the server admin. Requires working sendmail
