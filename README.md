# scripts
Various scripts &amp; tools


#### cidr2ip.sh
```
convert CIDR to IP address list from single CIDR or list file
output to 'iplist-<timestamp>.txt' in working directory
```
#### domreg-enum.sh
```
enumerate registered domains from Org name and email domain
output to csv containing domain, restistrar, reg/exp dates, reg org, reg email, IP address, & hosting org
```
#### geotracker.sh
```
lookup country/city/state/long/lat for IP address or list file
zip contains a resource directory containing country flags, bash html, & country codes csv
IP address output is print to STDOUT 
file output is html & includes country flag for copy/paste into IR report, etc
```
#### host-enum.sh
```
perform host look-up and compare to known domains
```
#### icmp-ts-req.sh
```
check for host response to ICMP Timestamp
```
#### ike-xfm-scan.sh
```
ike-scan scipt to test common transforms
```
#### iplist-gen.sh
```
generate IP address list from file containing mix of single IP address, range, and/or CIDR
output to 'iplist-<timestamp>.txt' in working directory
```
#### ping-sweeper
```
pings hosts from range, CIDR, or list file
```
#### rir-lookup.sh
```
lookup RIR governing an IP address
requres accompanying 'ipv4-address-space.csv' - proided by IANA
output to 'rirlist.txt' in working directory
```
