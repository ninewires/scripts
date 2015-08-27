#!/bin/bash

# Script to check for host response to ICMP Timestamp
# Timestamp will be converted to current time of day & compared
# Output to stdout will display time in ms & H:M:S
#
# Edit local_tz variable below to adjust time offset to your locale
#
# Author: Jason Ashton
# Created: 08/24/2015
#

# Timezone offset - unsigned
local_tz=4


# Argument check & usage
sname=`basename "$0"`

if [ $# -ne 1 ]; then
        echo
        echo "Usage: $sname <ip_addr>"
        echo
        exit 1
fi

# Format Check
if ! [[ $1 =~ ^[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}$ ]]; then
	echo
	echo "$1 Does Not Contain a Valid IP Address" >&2
	echo
	exit 1
else
	:
fi

# Valid IP Address Check
addr=( $(echo $1 | tr \. " ") )

if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 \
|| ${addr[2]} -gt 255 || ${addr[3]} -gt 255 ]]; then
        echo
        echo "$1 Does Not Contain a Valid IP Address" >&2
        echo
        exit
else
	:
fi


# Ping host for timestamp reply
#ip_addr=$1
nping --icmp-type timestamp $1 > ts_tmp.txt

# Use Receive Time on count 5
time_ms=$(cat ts_tmp.txt | grep seq=5 | grep RCVD | cut -d" " -f13 | tr \= " " | awk '{print $2}')

# Check for Reply
if [[ $time_ms -eq 0 ]]; then
	echo
	echo "No Reply From Host"
	echo
	rm ts_tmp.txt
	exit 1
else
	:
fi

# Subract Local TZ from UTC
local_time=$(( $time_ms - ($local_tz * 3600000) ))

# Convert ms to s
time_s=$(echo "$local_time / 1000" | bc -l)

# Convert Hours
hours=$(echo "$time_s / 3600" | bc -l | cut -d"." -f1 | awk '{printf ("%02d\n", $1)}')

# Convert Minutes
hours_rem=$(echo "$time_s / 3600" | bc -l | cut -d"." -f2 | awk '{printf "."$1}')
mins=$(echo "$hours_rem * 60" | bc -l | cut -d"." -f1 | awk '{printf ("%02d\n", $1)}')

# Convert Seconds
mins_rem=$(echo "$hours_rem * 60" | bc -l | cut -d"." -f2 | awk '{printf "."$1}')
secs=$(echo "$mins_rem * 60" | bc -l | cut -d"." -f1 | awk '{printf ("%02d\n", $1)}')

# Assemble Time in H:M:S
time_hms=$(echo "$hours $mins $secs" | awk '{printf $1":"$2":"$3}')

time_now=$(date +"%T")

echo
echo "Host Reply Time in ms =		$time_ms"
echo "Host Reply Time in H:M:S =	$time_hms EDT"
echo "Current Time of Day =		$time_now"
echo

rm ts_tmp.txt
