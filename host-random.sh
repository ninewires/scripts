#!/bin/bash

# Script to generate random list of hosts from file
#
# Usage: <script_name> <host_file> <host_qty>
#
# Author: Jason Ashton
# Created: 07/13/2015
#

# Argument check & usage
sname=`basename "$0"`

if [ $# -ne 2 ]; then
	echo
	echo "Usage: $sname <host_file> <host_qty>"
	echo
	exit 1
fi

# Error Check Function
function err_check {
        for i in "${err[@]}"; do
                if [ $i -eq 0 ]; then
                        exit
                else
                        :
                fi
        done
        unset err
        return
}

# Format Check
err=()
while read ipaddr; do
        if ! [[ $ipaddr =~ ^[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}$ ]]; then
                err+=($?)
                echo "In $1 [$ipaddr] Does Not Contain Valid IP Address" >&2
        else
                err+=($?)
        fi
done < $1

err_check


# Valid IP Address Check
err=()
while read ipaddr; do
        addr=( $(echo $ipaddr | tr \. " ") )
        if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 \
        || ${addr[2]} -gt 255 || (${addr[3]} -eq 0 || ${addr[3]} -gt 255) ]]; then
                err+=($?)
                echo "In $1 [$ipaddr] Does Not Contain Valid IP Address" >&2
        else
                err+=($?)
        fi
done < $1

# Randomize quantity from list
hosts=$1
qty=$2

shuf -n$qty $hosts | sort
