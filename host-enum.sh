#!/bin/bash

# Script to perform host look-up and compare to known domains
# Requires (2) input files for arguements:
#	1- ip addresses line-delimited
#	2- domain names line-delimited
#
# Usage: <script_name> <ip_addr_file> <domain_names_file>
#
# Output is in Nessus format: <host_name>[a.b.c.d]
#
# Author: Jason Ashton
# Created: 07/13/2015
#

# Argument check & usage
sname=`basename "$0"`

if [ $# -ne 2 ]; then
	echo
	echo "Usage: $sname <ip_addr_file> <domains_file>"
	echo
	exit 1
fi

# Error Check Function
err_check ()
{
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

# IP Format Check
err=()
while read ipaddr; do
	if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
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
		if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || (${addr[1]} -eq 0 || ${addr[1]} -gt 255) || (${addr[2]} -eq 0 || ${addr[2]} -gt 255) || (${addr[3]} -eq 0 || ${addr[3]} -gt 255) ]]; then
			err+=($?)
			echo "In $1 [$ipaddr] Does Not Contain Valid IP Address" >&2
		else
			err+=($?)
		fi
done < $1

err_check

# Valid Domain Name Check
err=()
while read domain; do
	if ! [[ $domain =~ ^[[:alnum:]]+\.[[:alnum:]]+?\.?[[:alnum:]]+?\.?[[:alnum:]]{2,3}$ ]]; then
		err+=($?)
	echo "In $2 [$domain] Does Not Contain Valid Domain Name" >&2
	else
		err+=($?)
	fi
done < $2

err_check

# Host look-up
ip=$1
domain=$2

while read addr; do
	host $addr | grep -f $domain | tr \. " " | awk '{print $10"."$11"."$12"."$13"."$14"["$4"."$3"."$2"."$1"]"}';
done < $ip
