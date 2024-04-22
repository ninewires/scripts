#!/bin/bash

# Converts mixed list to line delimited file of all possible IP addresses for live host enum
# File may contain:
#	Single IP: 192.168.1.100
#	Range: 192.168.1.1-192.168.1.15	## Range should be in oct4 only
#	CIDR: 192.168.1.0/24			## Network ID and broadcast address are removed
#
# Usage: <script_name> <scope_file>
#
# Script writes to file 'iplist-<current_time>.txt' in the current working directory
#
# Author: Jason Ashton (@ninewires)
# Created: 11/14/2015
# Overhauled: 12/22/2020
# CIDR notation revised, additional input validation & code tweaks 04/20/2024

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

if [ $# -ne 1 ]
then
	echo -e "\nUsage: $sname <scope_file>"
	exit 1
fi

# DOS file type check
if file $inputfile | grep 'with CRLF line terminators' 1>/dev/null
then
	echo -e "\n${RED}[!] ${NC}eeeeew ${WHT}$inputfile ${NC}is a Windoze format :-#"
	if ! locate dos2unix 1>/dev/null
	then
		echo -e "    Looks like you don't have ${WHT}dos2unix ${NC}on your system :-/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	else
		echo -e "    Looks like you've got ${WHT}dos2unix ${NC}installed though \o/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	fi
fi

# ASCII file with no line terminators check
if file $inputfile | grep 'ASCII text, with no line terminators' 1>/dev/null
then
	echo -e "\n${RED}[!] ${NC}Looks like ${WHT}$inputfile ${NC}is an ASCII file with no line terminators"
	echo -e "    Use ${WHT}echo ${NC}to add a new line: ${WHT}echo >> $inputfile${NC}"
	echo -e "    -- OR --"
	if ! locate dos2unix 1>/dev/null
	then
		echo -e "    Looks like you don't have ${WHT}dos2unix ${NC}on your system :-/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	else
		echo -e "    Looks like you've got ${WHT}dos2unix ${NC}installed though \o/"
		echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
		exit 1
	fi
fi

# UTF-8 file type check
if file $inputfile | grep 'UTF-8 Unicode text' 1>/dev/null
then
	echo -e "\n${RED}[!] ${NC}Looks like ${WHT}$inputfile ${NC}is a UTF-8 format file${NC}"
	echo -e "    Concvert to ASCII via: ${WHT}cat $inputfile | iconv -f utf-8 -t ascii//TRANSLIT > <new_file>${NC}"
	echo -e "    Get ${WHT}$inputfile ${NC}converted and try again."
	exit 1
fi

# Input validation
CNT=0
while IFS= read -r ipaddr
do
	# Check for whitespace on line
	if echo "$ipaddr" | grep -q -P ' |\t'
	then
		echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - This Line Contains Whitespace" 2>/dev/null
		let CNT++;
	else
		# Put IP address/range/CIDR in array
		addr=( $(echo $ipaddr | sed 's/[-|.|/]/ /g') )
		# Verirfy proper IP address format
		if [[ ${#addr[@]} -le 4 ]]
		then
			if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid IP Address" 2>/dev/null
				let CNT++;
			elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid IP Address" 2>/dev/null
				let CNT++;
			fi
		fi

		# Check for range format - full start/stop in octet 4 with no whitespace
		if [[ ${#addr[@]} -eq 8 ]]
		then
			if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid Range" 2>/dev/null
				let CNT++;
			elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || (${addr[4]} -eq 0 || ${addr[4]} -gt 255) || ${addr[5]} -gt 255 || ${addr[6]} -gt 255 || ${addr[7]} -gt 255 ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid Range" 2>/dev/null
				let CNT++;
			elif [[ ${addr[0]} -ne ${addr[4]} || ${addr[1]} -ne ${addr[5]} || ${addr[2]} -ne ${addr[6]} ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid Range - only octet 4 should represent range start/stop" 2>/dev/null
				let CNT++;
			fi
		fi

		# Verify CIDR notation
		if [[ ${#addr[@]} -eq 5 ]]
		then
			if ! [[ $ipaddr =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"/"[1-9]{1,2} ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${WHT}[$ipaddr]${NC} Is Not a Valid CIDR Format" 2>/dev/null
				let CNT++;
			elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 32 ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] Is Not a Valid CIDR Format" 2>/dev/null
				let CNT++;
			# Networks larger than /8 not a thing
			elif [[ ${addr[4]} -le 7 && ${addr[4]} -ge 0 ]]
			then
				echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Check for typo, ${WHT}/${addr[4]} ${NC}is larger than would ever be used" 2>/dev/null
				let CNT++;
			fi
		fi

		# Check for reserved ranges
		# CG-NAT range
		if [[ ${addr[0]} -eq 100 && (${addr[1]} -ge 64 && ${addr[1]} -le 127) ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# Localhost
		elif [[ ${addr[0]} -eq 127 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Seriously? We aren't gonna scan ourself" 2>/dev/null
			let CNT++;
		# Link-local range
		elif [[ ${addr[0]} -eq 169 && ${addr[1]} -eq 254 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# IETF protocol range
		elif [[ ${addr[0]} -eq 192 && ${addr[1]} -eq 0 && ${addr[2]} -eq 0 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# TEST-NET-1 documentation range
		elif [[ ${addr[0]} -eq 192 && ${addr[1]} -eq 0 && ${addr[2]} -eq 2 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# Former IPv6 to IPv4 relay range
		elif [[ ${addr[0]} -eq 192 && ${addr[1]} -eq 88 && ${addr[2]} -eq 99 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# Benchmark testing range
		elif [[ ${addr[0]} -eq 198 && ${addr[1]} -ge 18 && ${addr[1]} -le 19 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# TEST-NET-2 documentation range
		elif [[ ${addr[0]} -eq 198 && ${addr[1]} -eq 51 && ${addr[2]} -eq 100 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# TEST-NET-3 documentation range
		elif [[ ${addr[0]} -eq 203 && ${addr[1]} -eq 0 && ${addr[2]} -eq 113 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# Multicast range
		elif [[ ${addr[0]} -ge 224 && ${addr[0]} -le 239 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		# Reserved for future uses
		elif [[ ${addr[0]} -ge 240 && ${addr[0]} -le 255 ]]
		then
			echo -e "\n${RED}[!] ${NC}In ${YEL}$inputfile ${NC}[${WHT}$ipaddr${NC}] - Reserved Address" 2>/dev/null
			let CNT++;
		fi
	fi
done < $inputfile

# Check for errors & exit
if [[ $CNT -gt 0 ]]
then
	echo -e "\n${RED}Oops, fix these errors & try again${NC}"
	exit 1
fi

## Generate List
# Single IP address
while read input
do
	# Put IP address/range/CIDR in array
	addr2=( $(echo $input | sed 's/[-|.|/]/ /g') )
	if [[ ${#addr2[@]} -eq 4 ]]
	then
		echo $input >> tmpiplistgen
	fi
# IP address range
	if [[ ${#addr2[@]} -eq 8 ]]
	then
		rangelow=${addr2[3]}
		rangehigh=${addr2[7]}
		for rangeoct4 in $(seq $rangelow 1 $rangehigh)
		do
			echo ${addr2[0]}.${addr2[1]}.${addr2[2]}.$rangeoct4 >> tmpiplistgen
		done
	fi
# CIDR
	if [[ ${#addr2[@]} -eq 5 ]]
	then
		cidraddr=$(echo $addr2 | cut -d'/' -f1)
		prefix=${addr2[4]}
		# bit shift each octet the number of bits to create dec equiv & add
		ipdec=$(( (${addr2[0]} << 24) + (${addr2[1]} << 16) + (${addr2[2]} << 8) + ${addr2[3]} ))
		ipbin=$( echo "obase=2; ibase=10; $ipdec" | bc )
		netidbin=$(echo $ipbin | cut -c1-${prefix})
		hostbits=$(( 32 - $prefix ))
		hostbin=$(for i in $(seq 1 $hostbits); do echo -n '1'; done)
		# Host bits in dec
		hostdec=0
		for (( i=0; i<$hostbits; i++ ))
		do
			hostdec=$(( (hostdec << 1) ^ 1 ))
		done
		# Subnet mask in dec/hex
		maskdec=$(( $hostdec ^ 0xFFFFFFFF ))
		maskhex=$(echo "ibase=10;obase=16;$maskdec" | bc)
		# Convert subnet mask octets from hex to dec
		maskoct1=$(echo "obase=10; ibase=16; ${maskhex:0:2}" | bc)
		maskoct2=$(echo "obase=10; ibase=16; ${maskhex:2:2}" | bc)
		maskoct3=$(echo "obase=10; ibase=16; ${maskhex:4:2}" | bc)
		maskoct4=$(echo "obase=10; ibase=16; ${maskhex:6:2}" | bc)

		# Network ID - AND IP address with network prefix
		netid1=$(( ${addr2[0]} & $maskoct1 ))
		netid2=$(( ${addr2[1]} & $maskoct2 ))
		netid3=$(( ${addr2[2]} & $maskoct3 ))
		netid4=$(( ${addr2[3]} & $maskoct4 ))
		netid="$netid1.$netid2.$netid3.$netid4"
		# Broadcast address - concat network ID & host binary
		bcaddrbin=$(echo "${netidbin}${hostbin}")
		bcaddr1=$(echo "obase=10; ibase=2; ${bcaddrbin:0:8}" | bc)
		bcaddr2=$(echo "obase=10; ibase=2; ${bcaddrbin:8:8}" | bc)
		bcaddr3=$(echo "obase=10; ibase=2; ${bcaddrbin:16:8}" | bc)
		bcaddr4=$(echo "obase=10; ibase=2; ${bcaddrbin:24:8}" | bc)

		if [[ "$cidraddr" != "$netid" ]]
		then
			echo -e "${YEL}[!] ${NC}Note that ${YEL}$input ${NC}is not the proper start of a range and could be a typo."
		fi

		# Loop to create all possible IP addressess
		for w in $(seq $netid1 1 $bcaddr1)
		do
			for x in $(seq $netid2 1 $bcaddr2)
			do
				for y in $(seq $netid3 1 $bcaddr3)
				do
					for z in $(seq $netid4 1 $bcaddr4)
					do
						echo $w.$x.$y.$z >> tmpiplistgen2
					done
				done
			done
		done

		# Remove Network ID/Broadcast address
		if [[ ${addr2[4]} -ge 31 && ${addr2[4]} -le 32 ]]
		then
			cat tmpiplistgen2 >> tmpiplistgen
		else
			tlines=$(wc -l tmpiplistgen2 | sed -e 's|^ *||' | cut -d' ' -f1)
			lline=$(( $tlines - 1 ))
			sed -n 2,${lline}p tmpiplistgen2 >> tmpiplistgen
		fi
		rm tmpiplistgen2 2>/dev/null
	fi
done < $inputfile

# Dse-dupe & sort in proper IP address order
sort -uV tmpiplistgen >> $filename
rm tmpiplistgen* 2>/dev/null

# Stats
hostcount=$(wc -l $filename | sed -e 's|^ *||' | cut -d' ' -f1)
echo -e "\nSee ${WHT}$filename ${NC}in Current Working Dir"
echo -e "  ${WHT}$hostcount ${NC}Total Addresses\n"
