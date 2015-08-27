#!/bin/bash

# ike-scan scipt to test common transforms
#
# greps results for "Handshake returned & writes to
# file ike-<ip_addr>.txt in current directory
#
# Modified script from ike-scan user guide
# http://www.nta-monitor.com/wiki/index.php/Ike-scan_User_Guide
#
# Two Diffie-Hellman groups are included. The second includes values
# recommended in Cisco VPN config guide. Uncomment where desired
#
# Author: Jason Ashton
# Created: 08/24/2015
#

# Argument check & usage
sname=`basename "$0"`

if [ $# -ne 1 ]; then
        echo
        echo "Usage: $sname <ip_addr>"
        echo
        exit 1
fi

# Valid IP Address Check
addr=( $(echo $1 | tr \. " ") )

if ! [[ $1 =~ [1-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3} ]]; then
        echo
        echo "$1 Does Not Contain a Valid IP Address" >&2
        echo
        exit
else
        :
fi

if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 \
|| ${addr[2]} -gt 255 || ${addr[3]} -gt 255 ]]; then
        echo
        echo "$1 Does Not Contain a Valid IP Address"
        echo
        exit
else
        :
fi


# Encryption algorithms: DES(1), Triple-DES(5), AES/128(7), AES/192, AES/256
enclist="1 5 7/128 7/192 7/256"

# Hash algorithms: MD5(1), SHA1(2), SHA2-256(4), SHA2-384(5)
hashlist="1 2 4 5"

# Authentication methods: Pre-Shared Key(1), RSA Signatures(3), RSA Encryption(4),
# Hybrid Mode(64221), XAUTH(65001)
authlist="1 3 4 64221 65001"

# Diffie-Hellman groups: MODP 768(1), MODP 1024(2), MODP 1536(5), MODP 2048(14),
# MODP 3072(15), MODP 4096(16)
grouplist="1 2 5"
#grouplist="1 2 5 14 15 16"


for enc in $enclist; do
   for hash in $hashlist; do
      for auth in $authlist; do
         for group in $grouplist; do
            ike-scan -v $1 --trans=$enc,$hash,$auth,$group
         done
      done
   done
done > "tmp-ike.txt" 2>&1


# Check for returned handshake
cat tmp-ike.txt | grep -qi "Handshake returned"

# If handshake returned, write to file, if not delete tmp file & exit
if [ "$?" = "0" ]; then
	cat tmp-ike.txt | grep -C 1 "Handshake returned" > ike-$1.txt
	rm tmp-ike.txt
	echo
	echo "Handshake(s) returned!!"
	echo "See file 'ike-$1.txt' for the goods :-)"
	echo
else
	rm tmp-ike.txt
	echo
	echo "No Hanshake returned :-("
	echo "Better luck next time. . ."
	echo
fi
