#!/bin/bash

# Ping sweeper
#
# Requires (3) input files for arguements:
#       1- Class C Network ID
#       2- Lower Range
#       3- Upper range
#
# Usage: <script_name> <classC_net_id> <range_low> <range_high>
#
# ------or------
#
# Input from line delimited file
#
# ------or------
#
# CIDR Range
#
# Author: Jason Ashton
# Created: 07/13/2015
#

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

# Input From cmdline Function
cmdinput ()
{
        input=($REPLY)

	# Valid IP Address Check
        addr=( $(echo ${input[0]} | tr \. " " ) )

        if ! [[ ${input[0]} =~ [1-9]{,3}\.[0-9]{,3}\.[0-9]{,3} ]]; then
		echo
                echo "${input[0]} Does Not Contain a Valid IP Address" >&2
                echo
                menu
        else
                :
        fi

        if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 \
        || ${addr[2]} -gt 255 ]]; then
                echo
                echo "${input[0]} Does Not Contain a Valid IP Address"
                echo
                menu
        else
                :
	fi

        # Valid Range Check
        if ! [[ ${input[1]} -gt 255 || ${input[2]} -gt 255 || ${input[1]} -lt ${input[2]} ]]; then
                echo
                echo "${input[1]} & ${input[2]} Are Not a Valid Range" >&2
                echo "Either ${input[1]} Is > ${input[2]} Or One/Both Are > 255"
                echo
                menu
        else
                :
        fi

        netid=${input[0]}
        lower=${input[1]}
        upper=${input[2]}

        for ip in $(seq $lower $upper); do
        ping -c1 $netid.$ip | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
        done
return
}

# CIDR Input Function
cidrinput ()
{
	input=($REPLY)

	# Valid IP Address Check
	err=()
	addr=( $(echo $input | tr \. " " | tr \/ " ") )

	if ! [[ $input =~ [1-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}"/"[1-9]{1,2} ]]; then
        	err+=($?)
        	echo "$input Does Not Contain a Valid IP Address" >&2
	else
        	err+=($?)
	fi

	err_check

	if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 \
	|| ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 31 ]]; then
        	err+=($?)
        	echo "$input Does Not Contain a Valid IP Address"
	else
        	err+=($?)
	fi

	err_check

	# Generate IP Range List
	bits=`expr 32 - ${addr[4]}`
	total=$(echo 2^$bits - 1 | bc)
	low=`expr ${addr[3]} + 1`
	high=`expr ${addr[3]} + $total - 1`

	if [[ $bits -le 8 ]]; then
        	for range in $(seq $low $high); do
        	ping -c1 ${addr[0]}.${addr[1]}.${addr[2]}.$range | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
        	done
	else
        	echo "out of range"
		menu
	fi
return
}

fileinput ()
{
	input=($REPLY)
	# IP Format Check
	err=()
	while read ipaddr; do
        	if ! [[ $ipaddr =~ ^[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}$ ]]; then
                	err+=($?)
			echo "In $input [$ipaddr] Does Not Contain Valid IP Address" >&2
        	else
               	 	err+=($?)
        	fi
	done < $input

	err_check

	# Valid IP Address Check
	err=()
	while read ipaddr; do
        	addr=( $(echo $ipaddr | tr \. " ") )
        	if [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || (${addr[1]} -eq 0 || ${addr[1]} -gt 255) \
        	|| (${addr[2]} -eq 0 || ${addr[2]} -gt 255) || (${addr[3]} -eq 0 || ${addr[3]} -gt 255) ]]; then
                	err+=($?)
			echo "In $input [$ipaddr] Does Not Contain Valid IP Address" >&2
        	else
                	err+=($?)
       		fi
	done < $input

	err_check

	# Host Ping
	while read addr; do
		ping -c1 $addr | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
	done < $input
return
}

# Script Menu Function
menu ()
{
echo "
Please Select:

1. Address/Range Input
2. CIDR Notation Input
3. Input From File
0. Quit
"
read -p "Enter Selection [0-3] > "

if [[ $REPLY =~ ^[0-3]$ ]]; then
        if [[ $REPLY == 0 ]]; then
                echo "See Ya Next Time :-)"
                exit
        fi
        if [[ $REPLY == 1 ]]; then
                read -p "Enter <net_ID> <start_addr> <end_addr> > "
                echo
                cmdinput
        fi
        if [[ $REPLY == 2 ]]; then
                read -p "Enter CIDR Notation > "
                echo
                cidrinput
        fi
        if [[ $REPLY == 3 ]]; then
                read -p "Enter Filename For Input > "
                echo
                fileinput
        fi
fi
return
}

menu
