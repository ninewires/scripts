#!/bin/bash

# Converts mixed IP list to line delimited file for use in pingsweep, nmap, etc
# File may contain:
#	Single IP: 192.168.1.100
#	Range: 192.168.1.1-192.168.1.15
#	CIDR: 192.168.1.0/24			## Broadcast ID & Network ID are removed
#
# Usage: <script_name> <ip_file>
#
# Script writes to file 'iplist-<current_time>.txt' in the current working directory
#
# Author: Jason Ashton (@ninewires)
# Created: 11/14/2015

TIME=$(date +"%H%M%S")
filename="iplist-$TIME.txt"
inputfile=$1

GRN='\x1B[1;32m'
WHT='\x1B[1;37m'
RED='\x1B[1;31m'
YEL='\x1B[1;33m'
NC='\x1B[0m'

# Argument Check & Usage ###########################################################

sname=$(basename "$0")

if [ $# -ne 1 ]; then
	echo
	echo "Usage: $sname <source_file>"
	echo
	exit 1
fi

# File Type Check ##################################################################

if file $inputfile | grep 'with CRLF line terminators' 1>/dev/null; then
	echo
	echo -e "eeeeew ${WHT}$inputfile ${NC}is a windoze format"
	if ! locate dos2unix 1>/dev/null; then
		echo
		echo -e "Looks like you don't have ${WHT}dos2unix ${NC}on your system :-/"
		echo
		echo -e "Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	else
		echo
		echo -e "Looks like you've got ${WHT}dos2unix ${NC}installed though \o/"
		echo
		echo -e "Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	fi
fi

# Input Validation #################################################################

CNT=0

while read ipaddr; do
	addr=( $(echo $ipaddr | tr \. " " | tr \- " " | tr \/ " ") )
	# IP Address
	if [[ ${#addr[@]} -le 4 ]]; then
		if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			echo
			echo -e "In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid IP Address" >&2
			let CNT++;
		elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 ]]; then
			echo
			echo -e "In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid IP Address" >&2
			let CNT++;
		fi
	fi

	# Range
	if [[ ${#addr[@]} -eq 8 ]]; then
		 if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			echo
			echo -e "In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid Range" >&2
			let CNT++;
		elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || (${addr[4]} -eq 0 || ${addr[4]} -gt 255) || ${addr[5]} -gt 255 || ${addr[6]} -gt 255 || ${addr[7]} -gt 255 ]]; then
			echo
			echo -e "In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid Range" >&2
			let CNT++;
		fi
	fi

	# CIDR
	if [[ ${#addr[@]} -eq 5 ]]; then
		addr=( $(echo $ipaddr | tr \. " " | tr \/ " ") )
		if ! [[ $ipaddr =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"/"[1-9]{1,2} ]]; then
#          if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[1-9]{1,2}$ ]]; then
			echo
			echo -e "In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid CIDR Format" >&2
			let CNT++;
		elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 32 ]]; then
			echo
			echo -e "In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid CIDR Format" >&2
			let CNT++;
		fi
	fi

done < $inputfile

# Check for Errors & Exit ##########################################################

if [[ $CNT -gt 0 ]]; then
	echo
	echo -e "${RED}Oops, fix these errors & try again${NC}"
	echo
	exit 1
fi

#               ####################################################################
# Generate List ####################################################################
#               ####################################################################

# Single IP ########################################################################

while read input; do
	addr2=( $(echo $input | tr \. " " | tr \- " " | tr \/ " ") )

	if [[ ${#addr2[@]} -eq 4 ]]; then
		echo $input >> tmpiplistgen.txt
	fi

# IP Range #########################################################################

	if [[ ${#addr2[@]} -eq 8 ]]; then
		rangelow=${addr2[3]}
		rangehigh=${addr2[7]}
		for rangeoct4 in $(seq $rangelow 1 $rangehigh); do
		echo ${addr2[0]}.${addr2[1]}.${addr2[2]}.$rangeoct4 >> tmpiplistgen.txt
		done
	fi

# CIDR #############################################################################

	if [[ ${#addr2[@]} -eq 5 ]]; then
		bits=$(( 32 - ${addr2[4]} ))

		# Octet 1
		if [[ ${addr2[4]} -gt 0 && ${addr2[4]} -le 7 ]]; then
			oct1=$(( ((2**$bits - 1) / 16777216) | bc ))
			oct1low=${addr2[0]}
			oct1high=$(( (${addr2[0]} + $oct1) ))
			oct2low=0
			oct2high=255
			oct3low=0
			oct3high=255
			oct4low=0
			oct4high=255
		else
		#Octet 2
			if [[ ${addr2[4]} -ge 8 && ${addr2[4]} -le 15 ]]; then
				oct1low=${addr2[0]}
				oct1high=${addr2[0]}
				oct2=$(( ((2**$bits - 1) / 65536) | bc ))
				oct2low=${addr2[1]}
				oct2high=$(( (${addr2[1]} + $oct2) ))
				oct3low=0
				oct3high=255
				oct4low=0
				oct4high=255
			else
		# Octet 3
				if [[ ${addr2[4]} -ge 16 && ${addr2[4]} -le 23 ]]; then
					oct1low=${addr2[0]}
					oct1high=${addr2[0]}
					oct2low=${addr2[1]}
					oct2high=${addr2[1]}
					oct3=$(( ((2**$bits - 1) / 256) | bc ))
					oct3low=${addr2[2]}
					oct3high=$(( (${addr2[2]} + $oct3) ))
					oct4low=0
					oct4high=255
				else
		# Octet 4
					if [[ ${addr2[4]} -ge 24 ]]; then
						oct1low=${addr2[0]}
						oct1high=${addr2[0]}
						oct2low=${addr2[1]}
						oct2high=${addr2[1]}
						oct3low=${addr2[2]}
						oct3high=${addr2[2]}
						oct4=$(( (2**$bits - 1) | bc ))
						oct4low=$(( (${addr2[3]} + 1) ))               # Remove Network ID
						oct4high=$(( ((${addr2[3]} + $oct4) -1) ))     # Remove Broadcast ID
					fi
				fi
			fi
		fi

	# Generate IPs in CIDR
	for w in $(seq $oct1low 1 $oct1high); do
		for x in $(seq $oct2low 1 $oct2high); do
			for y in $(seq $oct3low 1 $oct3high); do
				for z in $(seq $oct4low 1 $oct4high); do
				echo $w.$x.$y.$z >> tmpiplistgen.txt
				done
			done
		done
	done

	fi

done < $inputfile

sort tmpiplistgen.txt -uV >> $filename
rm tmpiplistgen.txt 2>/dev/null

hostcount=$(cat $filename | wc -l)
echo
echo -e "See ${WHT}$filename ${NC}in Current Working Dir"
echo "  ${WHT}$hostcount ${NC}Total Addresses"
echo