#!/bin/bash

# Converts mixed IP list to line delimited file for use in pingsweep, nmap, etc
# File may contain:
#	Single IP: 192.168.1.100
#	Range: 192.168.1.1-192.168.1.15
#	CIDR: 192.168.1.0/24
#
# Usage: <script_name> <ip_file>
#
# Script writes to file 'iplist-<current_time>.txt' in the current working directory
#
# Author: Jason Ashton
# Created: 11/14/2015

TIME=$(date +"%H%M%S")
filename="iplist-$TIME.txt"
inputfile=$1

# Argument Check & Usage ###########################################################

sname=`basename "$0"`

if [ $# -ne 1 ]; then
        echo
        echo "Usage: $sname <source_file>"
        echo
        exit 1
fi

# Input Validation #################################################################

COLOR=`tput bold setaf 3`
NC=`tput sgr0`

CNT=0

while read ipaddr; do
     addr=( $(echo $ipaddr | tr \. " " | tr \- " " | tr \/ " ") )
     # IP Address
     if [[ ${#addr[@]} -eq 4 ]]; then
          if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid IP Address" >&2
               echo "    ex: 192.168.1.1"
               let CNT++;
          elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 ]]; then
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid IP Address" >&2
               echo "    ex: 192.168.1.1"
               let CNT++;
          else
               :
          fi
     else
          :
     fi

     # Range
     if [[ ${#addr[@]} -eq 8 ]]; then
           if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid Range" >&2
               echo "    ex: 192.168.1.1-192.168.1.64"
               let CNT++;
          elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || (${addr[4]} -eq 0 || ${addr[4]} -gt 255) || ${addr[5]} -gt 255 || ${addr[6]} -gt 255 || ${addr[7]} -gt 255 ]]; then
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid Range" >&2
               echo "    ex: 192.168.1.1-192.168.1.64"
               let CNT++;
          else
               :
          fi
     else
          :
     fi

     # CIDR
     if [[ ${#addr[@]} -eq 5 ]]; then
          if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[1-9]{1,2}$ ]]; then
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid CIDR Format" >&2
               echo "    ex: 192.168.1.0/24"
               let CNT++;
          elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 31 ]]; then
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid CIDR Format" >&2
               echo "    ex: 192.168.1.0/24"
               let CNT++;
          else
               :
          fi
     else
          :
     fi

done < $inputfile

# Check for Errors & Exit ##########################################################

if [[ $CNT -gt 0 ]]; then
     echo
     echo "Oops, fix these errors & try again"
     echo
     exit 1
else
     :
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
                              oct4low=$(( (${addr2[3]} + 1) ))               #Remove Network ID
                              oct4high=$(( ((${addr2[3]} + $oct4) -1) ))     #Remove Broadcast ID
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

cat tmpiplistgen.txt | uniq >> $filename
rm tmpiplistgen.txt

hostcount=$(cat $filename | wc -l)
echo
echo "See ${COLOR}$filename${NC} in Current Working Dir"
echo "  $hostcount Total Addresses"
echo
