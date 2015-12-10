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
filename="iplist-$TIME.txt"
COLOR=`tput bold setaf 3`
NC=`tput sgr0`

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

# Input Format Check Function
valid_cidr ()
{
     # Valid CIDR Check
     addr=( $(echo $ipaddr | tr \. " " | tr \/ " ") )

     if ! [[ $ipaddr =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"/"[1-9]{1,2} ]]; then
          err+=($?)
          echo "${COLOR}$input${NC} Is Not a Valid CIDR Format" >&2
          echo "ex: 192.168.1.0/24"
     elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 31 ]]; then
          err+=($?)
          echo "${COLOR}$input${NC} Is Not a Valid CIDR Format"
          echo "ex: 192.168.1.0/24"
     else
          err+=($?)
     fi

return
}

# IP List Gen Function
listgen ()
{
     addr=( $(echo $ipaddr | tr \. " " | tr \/ " ") )
     bits=$(( 32 - ${addr[4]} ))

     # Octet 1
     if [[ ${addr[4]} -gt 0 && ${addr[4]} -le 7 ]]; then
          oct1=$(( ((2**$bits - 1) / 16777216) | bc ))
          oct1low=${addr[0]}
          oct1high=$(( (${addr[0]} + $oct1) ))
          oct2low=0
          oct2high=255
          oct3low=0
          oct3high=255
          oct4low=0
          oct4high=255
     else
     #Octet 2
          if [[ ${addr[4]} -ge 8 && ${addr[4]} -le 15 ]]; then
               oct1low=${addr[0]}
               oct1high=${addr[0]}
               oct2=$(( ((2**$bits - 1) / 65536) | bc ))
               oct2low=${addr[1]}
               oct2high=$(( (${addr[1]} + $oct2) ))
               oct3low=0
               oct3high=255
               oct4low=0
               oct4high=255
          else
     # Octet 3
               if [[ ${addr[4]} -ge 16 && ${addr[4]} -le 23 ]]; then
                    oct1low=${addr[0]}
                    oct1high=${addr[0]}
                    oct2low=${addr[1]}
                    oct2high=${addr[1]}
                    oct3=$(( ((2**$bits - 1) / 256) | bc ))
                    oct3low=${addr[2]}
                    oct3high=$(( (${addr[2]} + $oct3) ))
                    oct4low=0
                    oct4high=255
               else
     # Octet 4
                    if [[ ${addr[4]} -ge 24 ]]; then
                         oct1low=${addr[0]}
                         oct1high=${addr[0]}
                         oct2low=${addr[1]}
                         oct2high=${addr[1]}
                         oct3low=${addr[2]}
                         oct3high=${addr[2]}
                         oct4=$(( (2**$bits - 1) | bc ))
                         oct4low=$(( (${addr[3]} + 1) ))               #Remove Network ID
                         oct4high=$(( ((${addr[3]} + $oct4) -1) ))     #Remove Broadcast ID
                    fi
               fi
          fi
     fi

     # Generate IPs in CIDR
     for w in $(seq $oct1low 1 $oct1high); do
          for x in $(seq $oct2low 1 $oct2high); do
               for y in $(seq $oct3low 1 $oct3high); do
                    for z in $(seq $oct4low 1 $oct4high); do
                    echo $w.$x.$y.$z >> cidrtmp.txt
                    done
               done
          done
     done

     cat cidrtmp.txt | sort -uV > $filename
     host_cnt=$(cat $filename | wc -l)
     rm cidrtmp.txt
     echo "See ${COLOR}$filename${NC} in current directory"
     echo "Total hosts = ${COLOR}$host_cnt${NC}"
     menu
return
}

# Input From cmdline Function
cidrinput ()
{
     ipaddr=$REPLY
     # Valid CIDR Check
     err=()
     valid_cidr
     err_check

     # Generate List
     listgen
return
}

# Input From File Function
fileinput ()
{
     input=$REPLY
     # Valid CIDR Check
     err=()
     while read ipaddr; do
          valid_cidr
     done < $input

     err_check

     # Generate List
     while read ipaddr; do
          listgen
     done < $input
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
          read -e -p "Enter Filename For Input > "
          echo
          fileinput
     fi
fi
return
}

menu
