#!/bin/bash

# Script to enumerate domains from client company name & email address
#
# Information will then be gathered for each domain, including:
# registrar, creation/expiration dates, registration org, reg email
# IP address, & hosting org
#
# Results will be written to a CSV file
#
# Author: Jason Ashton (@ninewires)
# Created: 03/17/2017

clear

GRN='\x1B[1;32m'
WHT='\x1B[1;37m'
RED='\x1B[1;31m'
NC='\x1B[0m'

# Catch termination
trap f_term SIGHUP SIGINT SIGTERM

f_term()
{
echo
echo -e "${RED}[!] ${WHT}Caught ${RED}ctrl+c${WHT}, removing all tmp files.${NC}"
rm tmpcurl1 tmpcurl2 tmpdomainlist tmpwhois tmpoutfile $outfile 2>/dev/null
exit 1
}

# Get client name
echo
echo -e -n "Enter Client Name: "
read -e orgname

while [[ $orgname == "" ]]; do
     echo
     echo -e -n "Client name is ${RED}empty${NC}, please try again: "
     read -e orgname
done
orgnamehtml=$(echo $orgname | sed 's| |%20|g;s|-|%2D|g;s|,|%2C|g;s|\.|%2E|g;s|\&|%26|g')

# Get client email domain
echo
echo -e -n "Enter Client Email Domain: "
read -e emaildomain

while ! [[ $emaildomain =~ ^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}$ ]]; do
     echo
     echo -e "${RED}$emaildomain ${NC}Is Not Valid Domain Format" >&2
     echo -e -n "Ex: homedepot.com or home-depot.com, Try Again: "
     read -e emaildomain
done
outfile=$(echo $emaildomain | cut -d'.' -f1 | sed 's|$|_domains.csv|g')

# get domains registered by target email address domain
curl --silent http://viewdns.info/reversewhois/?q=%40$emaildomain > tmpcurl1
sleep 2
curl --silent http://viewdns.info/reversewhois/?q=$orgnamehtml > tmpcurl2

if grep 'There are 0 domains' tmpcurl1 && grep 'There are 0 domains' tmpcurl2; then
	echo
	echo -e "${RED}[!] ${WHT}No ${RED}$emaildomain ${WHT}& ${RED}$orgname ${WHT}not found :-(${NC}"
	rm tmpcurl1 tmpcurl2
	exit 1
elif ! [ -s tmpcurl1 ] && ! [ -s tmpcurl2 ]; then
	echo
	echo -e "${RED}[!] ${WHT}No ${RED}$emaildomain ${WHT}& ${RED}$orgname ${WHT}not found :-(${NC}"
	rm tmpcurl1 tmpcurl2
	exit 1
else
	# generate list of domains registered by email address domain
	grep 'ViewDNS.info' tmpcurl1 | sed 's|<tr>|\n|g' | grep '</td></tr>' | grep -v -E 'font size|Domain Name' | cut -d'>' -f2 | cut -d'<' -f1 > tmpdomainlist
	grep 'ViewDNS.info' tmpcurl2 | sed 's|<tr>|\n|g' | grep '</td></tr>' | grep -v -E 'font size|Domain Name' | cut -d'>' -f2 | cut -d'<' -f1 >> tmpdomainlist
	sort -uV tmpdomainlist -o tmpdomainlist
	domcount=$(wc -l tmpdomainlist | sed -e 's|^[ \t]*||' | cut -d' ' -f1)
	echo 'AAAAA--placeholder--' > tmpoutfile
	echo
	echo -e "${GRN}[*] ${WHT}Found ${GRN}$domcount ${WHT}domains for ${GRN}$orgname ${WHT}& ${GRN}$emaildomain${NC}"
	echo
	echo -e "${GRN}[*] ${WHT}Enumerating domain details. . .${NC}"

	# loop thru domain list gathering details about the domain
	while read domain; do
		whois -H $domain 2>&1 | sed -e 's|^[ \t]*||' | sed 's| \+ ||g' | sed 's|: |:|g' > tmpwhois
		nomatch=$(grep -c -E 'No match for|Name or service not known' tmpwhois)
		if [[ $nomatch -eq 1 ]]; then
			echo "$domain -- No Whois Matches Found" >> tmpoutfile
		else
			registrar=$(grep -m1 'Registrar:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'Creation Date:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			regexpdate=$(grep -m1 'Expiration Date:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			regorg=$(grep -m1 'Registrant Organization:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,$regdate--$regexpdate,$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr | sed 's| \+ ||g' | grep 'Organization' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,$regdate--$regexpdate,$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		fi
		let number=number+1
		echo -ne "\t${GRN}$number ${WHT}of ${GRN}$domcount ${WHT}domains${NC}"\\r
    	
		sleep 2
	done < tmpdomainlist
fi

echo
echo -e "${GRN}[*] ${WHT}All finished. Results can be found in ${GRN}$outfile ${WHT}in the current directory.${NC}"
sort tmpoutfile | sed 's|AAAAA--placeholder--|Domain,Registrar,Create--Exp Date,Registration Org,Reg Email,IP Address,Host Org|' > $outfile

rm tmpcurl1 tmpcurl2 tmpdomainlist tmpwhois tmpoutfile 2>/dev/null