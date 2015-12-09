#!/bin/bash

# Converts CIDR Range to IP List For Use in Pingsweep, etc
#
# Usage: <script_name> <ip_addr/subnet>
#
# ------or------
#
# Input from line delimited file
#
# Script writes to file 'iplist-<current_time>.txt' in current directory
# when taking in a file, only unique values will be written
#
# Currently, the file will be overwritten if it already exists
#
# Author: Jason Ashton
# Created: 07/13/2015
#

TIME=$(date +"%H%M%S")
filename="iplist-$TIME.txt)

# Error Check Function
err_check ()
{
        for i in "${err[@]}"; do
                if [ $i -eq 0 ]; then
                        echo
			echo "Ooops! Fix & Try Again"
			menu
                else
                        :
                fi
        done
        unset err
        return
}

# Input From cmdline Funcion
cidrinput ()
{
	input=($REPLY)
	# Valid IP Address Check
	err=()
	addr=( $(echo $input | tr \. " " | tr \/ " ") )

	if ! [[ $input =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"/"[1-9]{1,2} ]]; then
		err+=($?)
		echo "$input Is Not a Valid CIDR Format" >&2
		echo "ex: 192.168.1.0/24"
	else
		err+=($?)
	fi

	err_check

	if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 \
	|| ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 31 ]]; then
		err+=($?)
		echo "$input Is Not a Valid CIDR Format"
		echo "ex: 192.168.1.0/24"
	else
        	err+=($?)
	fi

	err_check

	# Generate IP Range List
	bits=$(( 32 - ${addr[4]} ))
	total=$(( (2**$bits - 1) | bc ))
	low=$(( ${addr[3]} + 1 ))
	high=$(( (${addr[3]} + $total) - 1 ))

	if [[ $bits -le 8 ]]; then
		for range in $(seq $low $high); do
			echo ${addr[0]}.${addr[1]}.${addr[2]}.$range >> listtmp.txt
		done
	else
		echo "out of range"
	fi
	cat listtmp.txt | uniq > $filename
	host_cnt=$(cat $filename | wc -l)
	rm listtmp.txt
        echo "See $filename in current directory"
        echo "Total hosts = $host_cnt"
	menu
return
}

fileinput ()
{
        input=($REPLY)
        # IP Format Check
        err=()
        while read ipaddr; do
        	if ! [[ $ipaddr =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"/"[1-9]{1,2} ]]; then
                        err+=($?)
                        echo "In $input [$ipaddr] Does Not Contain Valid CIDR Format" >&2
			echo "ex: 192.168.1.0/24"
                else
                        err+=($?)
                fi
        done < $input

        err_check

        # Valid IP Address Check
        err=()
        while read ipaddr; do
                addr=( $(echo $ipaddr | tr \. " " | tr \/ " ") )
		if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 \
        	|| ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 31 ]]; then
                        err+=($?)
                        echo "In $input [$ipaddr] Does Not Contain Valid CIDR Format" >&2
			echo "ex: 192.168.1.0/24"
                else
                        err+=($?)
                fi
        done < $input

	err_check

	# Generate IP Range List
        while read ipaddr; do
                addr=( $(echo $ipaddr | tr \. " " | tr \/ " ") )
		bits=$(( 32 - ${addr[4]} ))
        	total=$(( (2^$bits - 1) | bc ))
        	low=$(( ${addr[3]} + 1 ))
        	high=$(( (${addr[3]} + $total) - 1 ))

        	if [[ $bits -le 8 ]]; then
                	for range in $(seq $low $high); do
                        	echo ${addr[0]}.${addr[1]}.${addr[2]}.$range >> listtmp.txt
                	done
        	else
                	echo "out of range"
        	fi
	done < $input
	cat listtmp.txt | uniq > cidr2ip-list.txt
        host_cnt=$(cat cidr2ip-list.txt | wc -l)
        rm listtmp.txt
        echo "See $filename in current directory"
        echo "Total hosts = $host_cnt"
	menu
return
}

# Script Menu Function
menu ()
{
echo "
Please Select:

1. Input CIDR Format
2. Input From File
0. Quit
"
read -p "Enter Selection [0-2] > "

if [[ $REPLY =~ ^[0-3]$ ]]; then
        if [[ $REPLY == 0 ]]; then
		echo
                echo "See Ya Next Time :-)"
		echo
                exit
        fi
        if [[ $REPLY == 1 ]]; then
                read -p "Enter CIDR Notation > "
                echo
                cidrinput
        fi
        if [[ $REPLY == 2 ]]; then
                read -p "Enter Filename For Input > "
                echo
                fileinput
        fi
fi
return
}

menu


