#!/bin/bash

# Ping sweeper
#
# Usage: <script_name> <start_addr>-<end_addr>
#
# ------or------
#
# Input from line delimited mixed format file
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

COLOR=`tput bold setaf 3`
NC=`tput sgr0`

# Input From cmdline Function
cmdinput ()
{
     err=()
     input=($REPLY)

     #Valid IP Range Check
     addr=( $(echo ${input[0]} | tr \. " " | tr \- " ") )

     if ! [[ $input =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
          err+=($?)
          echo
          echo "${COLOR}[$input]${NC} Is Not a Valid IP Range" >&2
          echo "    ex: 192.168.1.1-192.168.1.64"
          echo
          err+=($?)
          menu
     elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || (${addr[4]} -eq 0 || ${addr[4]} -gt 255) || ${addr[5]} -gt 255 || ${addr[6]} -gt 255 || ${addr[7]} -gt 255 ]]; then
          err+=($?)
          echo
          echo "${COLOR}[$input]${NC} Is Not a Valid IP Range" >&2
          echo "    ex: 192.168.1.1-192.168.1.64"
          echo
          err+=($?)
          menu
     else
          err+=($?)
     fi

     err_check

     # Ping Sweep
     netid="${addr[0]}.${addr[1]}.${addr[2]}"
     lower=${addr[3]}
     upper=${addr[7]}
     for ip in $(seq $lower $upper); do
          ping -c1 $netid.$ip | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
     done
return
}

# CIDR Input Function
cidrinput ()
{
     err=()
     input=($REPLY)

     # Valid IP Address Check
     addr=( $(echo $input | tr \. " " | tr \/ " ") )

     if ! [[ $input =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"/"[1-9]{1,2} ]]; then
          err+=($?)
          echo "${COLOR}[$input]${NC} Is Not Valid CIDR Notation" >&2
          echo "    ex: 192.168.1.0/24"
          err+=($?)
     elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 31 ]]; then
          err+=($?)
          echo "${COLOR}[$input]${NC} Is Not Valid CIDR Notation" >&2
          echo "    ex: 192.168.1.0/24"
          err+=($?)
     else
          err+=($?)
     fi

     err_check

     # Generate IP Range List
     bits=$(( (32 - ${addr[4]}) ))

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
                         ping -c1 $w.$x.$y.$z | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
                    done
               done
          done
     done

return
}

fileinput ()
{
inputfile=($REPLY)
err=()

while read ipaddr; do
     addr=( $(echo $ipaddr | tr \. " " | tr \- " " | tr \/ " ") )
     # IP Address
     if [[ ${#addr[@]} -eq 4 ]]; then
          if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
               err+=($?)
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid IP Address" >&2
               echo "    ex: 192.168.1.1"
               err+=($?)
          elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 ]]; then
               err+=($?)
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid IP Address" >&2
               echo "    ex: 192.168.1.1"
               err+=($?)
          else
               err+=($?)
          fi
     else
          err+=($?)
     fi

     # Range
     if [[ ${#addr[@]} -eq 8 ]]; then
           if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
               err+=($?)
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid Range" >&2
               echo "    ex: 192.168.1.1-192.168.1.64"
               err+=($?)
          elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || (${addr[4]} -eq 0 || ${addr[4]} -gt 255) || ${addr[5]} -gt 255 || ${addr[6]} -gt 255 || ${addr[7]} -gt 255 ]]; then
               err+=($?)
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid Range" >&2
               echo "    ex: 192.168.1.1-192.168.1.64"
               err+=($?)
          else
               err+=($?)
          fi
     else
          err+=($?)
     fi

     # CIDR
     if [[ ${#addr[@]} -eq 5 ]]; then
          if ! [[ $ipaddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[1-9]{1,2}$ ]]; then
               err+=($?)
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid CIDR Format" >&2
               echo "    ex: 192.168.1.0/24"
               err+=($?)
          elif [[ (${addr[0]} -eq 0 || ${addr[0]} -gt 255) || ${addr[1]} -gt 255 || ${addr[2]} -gt 255 || ${addr[3]} -gt 255 || ${addr[4]} -gt 31 ]]; then
               err+=($?)
               echo
               echo "In $inputfile ${COLOR}[$ipaddr]${NC} Is Not a Valid CIDR Format" >&2
               echo "    ex: 192.168.1.0/24"
               err+=($?)
          else
               err+=($?)
          fi
     else
          err+=($?)
     fi

done < $inputfile

err_check

#               ####################################################################
# Generate List ####################################################################
#               ####################################################################

# Single IP ########################################################################

while read input; do
     addr=( $(echo $input | tr \. " " | tr \- " " | tr \/ " ") )

     if [[ ${#addr[@]} -eq 4 ]]; then
          ping -c1 $input | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
     fi

# IP Range #########################################################################

     if [[ ${#addr[@]} -eq 8 ]]; then
          lower=${addr[3]}
          upper=${addr[7]}
          netid="${addr[0]}.${addr[1]}.${addr[2]}"
          for ip in $(seq $lower 1 $upper); do
               ping -c1 $netid.$ip | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
          done
     fi

# CIDR #############################################################################

     if [[ ${#addr[@]} -eq 5 ]]; then
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
                    ping -c1 $w.$x.$y.$z | grep "from" | cut -d" " -f4 | cut -d":" -f1 &
                    done
               done
          done
     done

     fi

done < $inputfile

return
}

# Script Menu Function
menu ()
{
echo "
Please Select:

1. Address Range Input
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
          read -p "Enter <start_addr>-<end_addr> > "
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

