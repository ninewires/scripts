#!/bin/bash

# Converts mixed IP list to line delimited file for live host enum
# File may contain:
#	Single IP: 192.168.1.100
#	Range: 192.168.1.1-192.168.1.15
#	CIDR: 192.168.1.0/24			## Broadcast ID & Network ID are removed
#
# Usage: <script_name> <scope_file>
#
# Script writes to file 'iplist-<current_time>.txt' in the current working directory
#
# Author: Jason Ashton (@ninewires)
# Created: 11/14/2015
# Overhauled: 12/22/2020

TIME=$(date +"%H%M%S")
filename="iplist-$TIME.txt"
inputfile=$1

GRN='\x1B[1;32m'
WHT='\x1B[1;37m'
RED='\x1B[1;31m'
YEL='\x1B[1;33m'
NC='\x1B[0m'

# Argument Check & Usage
sname=$(basename "$0")

if [ $# -ne 1 ]; then
	echo -e "\nUsage: $sname <scope_file>"
	exit 1
fi

# DOS File Type Check
if file $inputfile | grep 'with CRLF line terminators' 1>/dev/null; then
	echo -e "\n${RED}[!] ${NC}eeeeew ${WHT}$inputfile ${NC}is a windoze format :-#"
	if ! locate dos2unix 1>/dev/null; then
		echo -e "    Looks like you don't have ${WHT}dos2unix ${NC}on your system :-/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	else
		echo -e "    Looks like you've got ${WHT}dos2unix ${NC}installed though \o/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	fi
fi

# ASCII File With no Line Terminators Check
if file $inputfile | grep 'ASCII text, with no line terminators' 1>/dev/null; then
	echo -e "\n${RED}[!] ${NC}Looks like ${WHT}$inputfile ${NC}is an ASCII file with no line terminators"
	echo -e "    Use ${WHT}echo ${NC}to add a new line: ${WHT}echo >> $inputfile${NC}"
	echo -e "    -- OR --"
	if ! locate dos2unix 1>/dev/null; then
		echo -e "    Looks like you don't have ${WHT}dos2unix ${NC}on your system :-/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	else
		echo -e "    Looks like you've got ${WHT}dos2unix ${NC}installed though \o/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	fi
fi

# UTF-8 File Type Check
if file $inputfile | grep 'UTF-8 Unicode text' 1>/dev/null; then
	echo -e "\n${RED}[!] ${NC}Looks like ${WHT}$inputfile ${NC}is a UTF-8 format file${NC}"
	echo -e "    Concvert to ASCII via: ${WHT}cat $inputfile | iconv -f utf-8 -t ascii//TRANSLIT > <new_file>${NC}"
	echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
	exit 1
fi

# Input Validation
CNT=0

while IFS= read -r ipaddr; do
	# Whitespace
	if echo "$ipaddr" | grep -q -P ' |\t'; then
		echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - This Line Contains Whitespace" 2>/dev/null
		let CNT++;
	else
		addr=( $(echo $ipaddr | tr '.' ' ' | tr '-' ' ' | tr '/' ' ') )
		# IP Address
		if [[ ${#addr[@]} -le 4 ]]; then
			if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid IP Address" 2>/dev/null
				let CNT++;
			elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid IP Address" 2>/dev/null
				let CNT++;
			elif [[ ${addr[0]} -eq 127 ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Seriously? We aren't gonna scan ourself" 2>/dev/null
				let CNT++;
			fi
		fi

		# Range
		if [[ ${#addr[@]} -eq 8 ]]; then
			if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid Range" 2>/dev/null
				let CNT++;
			elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || (${addr[4]} -eq 0 || ${addr[4]} -gt 255) || ${addr[5]} -gt 255 || ${addr[6]} -gt 255 || ${addr[7]} -gt 255 ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid Range" 2>/dev/null
				let CNT++;
			fi
		fi

		# CIDR
		if [[ ${#addr[@]} -eq 5 ]]; then
			if ! [[ $ipaddr =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"/"[1-9]{1,2} ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid CIDR Format" 2>/dev/null
				let CNT++;
			elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 32 ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid CIDR Format" 2>/dev/null
				let CNT++;
			# networks larger than /8 not a thing
			elif [[ ${addr[4]} -le 7 && ${addr[4]} -ge 0 ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Check for typo, ${WHT}/${addr[4]} ${NC}Is Larger Than We Would Ever Use" 2>/dev/null
				let CNT++;
			# oct4 should be zero for subnets <=24
			elif [[ ${addr[4]} -le 24 && ${addr[3]} -ne 0 ]]; then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - ${WHT}${addr[3]} ${NC}Is Not a Valid Start Address for ${WHT}/${addr[4]} ${NC}Network" 2>/dev/null
				let CNT++;
			# oct4 start address for /25 to /30 - should be any binary multiple, but not cross a /24 boundary
			elif [[ ${addr[4]} -ge 25 && ${addr[4]} -le 30 ]]; then
				bits=$(( 32 - ${addr[4]} ))
				taddr=$(( 2**${bits} ))
				laddr=$(( ${addr[3]} + $taddr - 1 ))
				if [[ $laddr -gt 255 ]]; then
					echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} - ${WHT}${addr[3]} ${NC}Start Address & ${WHT}/${addr[4]} ${NC}Network Will Cross /24 Boundary (Unlikely)" 2>/dev/null
					let CNT++;
				fi
			fi
		fi

		# Reserved
		if [[ ${addr[0]} -eq 100 && (${addr[1]} -ge 64 && ${addr[1]} -le 127) ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		elif [[ ${addr[0]} -eq 169 && ${addr[1]} -eq 254 ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		elif [[ ${addr[0]} -eq 192 && ${addr[1]} -eq 0 && ${addr[2]} -eq 0 ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		elif [[ ${addr[0]} -eq 192 && ${addr[1]} -eq 0 && ${addr[2]} -eq 2 ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		elif [[ ${addr[0]} -eq 198 && ${addr[1]} -eq 51 && ${addr[2]} -eq 100 ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		elif [[ ${addr[0]} -eq 203 && ${addr[1]} -eq 0 && ${addr[2]} -eq 113 ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		elif [[ ${addr[0]} -ge 224 && ${addr[0]} -le 239 ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		elif [[ ${addr[0]} -ge 240 && ${addr[0]} -le 255 ]]; then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		fi
	fi
done < $inputfile

# Check for Errors & Exit
if [[ $CNT -gt 0 ]]; then
	echo -e "\n${RED}Oops, fix these errors & try again${NC}"
	exit 1
fi

## Generate List
# Single IP
while read input; do
	addr2=( $(echo $input | tr '.' ' ' | tr '-' ' ' | tr '/' ' ') )
	if [[ ${#addr2[@]} -eq 4 ]]; then
		echo $input >> tmpiplistgen
	fi
# IP Range
	if [[ ${#addr2[@]} -eq 8 ]]; then
		rangelow=${addr2[3]}
		rangehigh=${addr2[7]}
		for rangeoct4 in $(seq $rangelow 1 $rangehigh); do
			echo ${addr2[0]}.${addr2[1]}.${addr2[2]}.$rangeoct4 >> tmpiplistgen
		done
	fi
# CIDR	
	if [[ ${#addr2[@]} -eq 5 ]]; then
		bits=$(( 32 - ${addr2[4]} ))
		# Oct1
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
		#Oct2
		elif [[ ${addr2[4]} -ge 8 && ${addr2[4]} -le 15 ]]; then
			oct1low=${addr2[0]}
			oct1high=${addr2[0]}
			oct2=$(( ((2**$bits - 1) / 65536) | bc ))
			oct2low=${addr2[1]}
			oct2high=$(( (${addr2[1]} + $oct2) ))
			oct3low=0
			oct3high=255
			oct4low=0
			oct4high=255
		# Oct3
		elif [[ ${addr2[4]} -ge 16 && ${addr2[4]} -le 23 ]]; then
			oct1low=${addr2[0]}
			oct1high=${addr2[0]}
			oct2low=${addr2[1]}
			oct2high=${addr2[1]}
			oct3=$(( ((2**$bits - 1) / 256) | bc ))
			oct3low=${addr2[2]}
			oct3high=$(( (${addr2[2]} + $oct3) ))
			oct4low=0
			oct4high=255
		# Oct4
		elif [[ ${addr2[4]} -ge 24 && ${addr2[4]} -le 30 ]]; then
			oct1low=${addr2[0]}
			oct1high=${addr2[0]}
			oct2low=${addr2[1]}
			oct2high=${addr2[1]}
			oct3low=${addr2[2]}
			oct3high=${addr2[2]}
			oct4=$(( (2**$bits - 1) | bc ))
			oct4low=${addr2[3]}
			oct4high=$(( (${addr2[3]} + $oct4) ))
		#/31
		elif [[ ${addr2[4]} -eq 31 ]]; then
			oct1low=${addr2[0]}
			oct1high=${addr2[0]}
			oct2low=${addr2[1]}
			oct2high=${addr2[1]}
			oct3low=${addr2[2]}
			oct3high=${addr2[2]}
			oct4low=${addr2[3]}
			oct4high=$(( (${addr2[3]} + 1) ))
		#/32
		elif [[ ${addr2[4]} -eq 32 ]]; then
			oct1low=${addr2[0]}
			oct1high=${addr2[0]}
			oct2low=${addr2[1]}
			oct2high=${addr2[1]}
			oct3low=${addr2[2]}
			oct3high=${addr2[2]}
			oct4low=${addr2[3]}
			oct4high=${addr2[3]}
		fi
	# Generate IPs from CIDR
		for w in $(seq $oct1low 1 $oct1high); do
			for x in $(seq $oct2low 1 $oct2high); do
				for y in $(seq $oct3low 1 $oct3high); do
					for z in $(seq $oct4low 1 $oct4high); do
						echo $w.$x.$y.$z >> tmpiplistgen2
					done
				done
			done
		done

		# Remove Network/Broadcast IDs
		if [[ ${addr2[4]} -ge 31 && ${addr2[4]} -le 32 ]]; then
			cat tmpiplistgen2 >> tmpiplistgen
		else
			tlines=$(wc -l tmpiplistgen2 | sed -e 's|^ *||' | cut -d' ' -f1)
			lline=$(( $tlines - 1 ))
			sed -n 2,${lline}p tmpiplistgen2 >> tmpiplistgen
		fi
		rm tmpiplistgen2 2>/dev/null
	fi
done < $inputfile

sort -uV tmpiplistgen >> $filename
rm tmpiplistgen* 2>/dev/null

hostcount=$(wc -l $filename | sed -e 's|^ *||' | cut -d' ' -f1)
echo -e "\nSee ${WHT}$filename ${NC}in Current Working Dir"
echo -e "  ${WHT}$hostcount ${NC}Total Addresses\n"
