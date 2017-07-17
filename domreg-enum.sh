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
orgnamehtml=$(echo $orgname | sed 's| |\+|g;s|-|%2D|g;s|,|%2C|g;s|\.|%2E|g;s|\&|%26|g')

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
sleep 5
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
#elif grep -Fq 'paymenthash' tmpcurl1 || grep -Fq 'paymenthash' tmpcurl2; then
	# generate list of domains registered by email address domain - large result count
	grep 'Domain Name' tmpcurl1 | sed 's|<tr>|\n|g' | grep '</td></tr>' | cut -d'>' -f2 | cut -d'<' -f1 | grep -v 'Domain Name' > tmpdomainlist
	grep 'Domain Name' tmpcurl2 | sed 's|<tr>|\n|g' | grep '</td></tr>' | cut -d'>' -f2 | cut -d'<' -f1 | grep -v 'Domain Name' >> tmpdomainlist
	# generate list of domains registered by email address domain
	grep 'ViewDNS.info' tmpcurl1 | sed 's|<tr>|\n|g' | grep '</td></tr>' | grep -v -E 'font size|Domain Name' | cut -d'>' -f2 | cut -d'<' -f1 >> tmpdomainlist
	grep 'ViewDNS.info' tmpcurl2 | sed 's|<tr>|\n|g' | grep '</td></tr>' | grep -v -E 'font size|Domain Name' | cut -d'>' -f2 | cut -d'<' -f1 >> tmpdomainlist
fi
sed -i '/^$/d' tmpdomainlist | sort -uV tmpdomainlist -o tmpdomainlist

domcount=$(wc -l tmpdomainlist | sed -e 's|^[ \t]*||' | cut -d' ' -f1)
echo '111AAA--placeholder--' > tmpoutfile
echo
echo -e "${GRN}[*] ${WHT}Found ${GRN}$domcount ${WHT}domains for ${GRN}$orgname ${WHT}& ${GRN}$emaildomain${NC}"
echo
echo -e "${GRN}[*] ${WHT}Enumerating domain details. . .${NC}"

# loop thru domain list gathering details about the domain
while read domain; do
	whois $domain 2>&1 > tmpwhois
	nomatch=$(grep -c -E 'No match for|Name or service not known' tmpwhois)
	if [[ $nomatch -eq 1 ]]; then
		echo "$domain, -- No Whois Matches Found" >> tmpoutfile
	else
		# .au .ae 
		if grep 'A.B.N. SEARCH' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			registrar=$(grep -m1 'Registrar Name:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regorg=$(grep -m1 -E 'Registrant:|Registrant Contact Organisation:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Registrant Contact Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
					echo "$domain,$registrar,--,$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
					ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
					hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
					echo "$domain,$registrar,--,$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .uk
		elif grep 'Copyright Nominet' tmpwhois; then
			sed -i -e 's|^[ \t]*||' tmpwhois        					#remove leading white space
			sed -i 's|\s*$||g' tmpwhois             					#remove trailing white space
			sed -i -e ':a' -e 'N' -e '$!ba' -e 's/:\n/:/g' tmpwhois		#replace colon line feed with nothing
			sed -i 's|: \{1,\}|:|g' tmpwhois							#replace colon white space with colon
			sed -i 's|Relevant dates:||' tmpwhois						#remove 'Relevant dates'
			registrar=$(grep -m1 'Registrar:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'Registered on:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expiry date:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'Registrant:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
					echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
					ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
					hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
					echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .sg
		elif grep 'SGNIC' tmpwhois; then
			sed -i -e 's|^[ \t]*||' tmpwhois	#remove leading white space
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			sed -i 's|\t||g' tmpwhois			#remove tab
			sed -i '/^$/d' tmpwhois				#remove blank lines
			registrar=$(grep -m1 'Registrar:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'Creation Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'Expiration Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -A1 'Registrant:' tmpwhois | grep 'Name:' | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .fi .no
		elif grep -E 'NORID|Finnish Communications' tmpwhois;then
			sed -i 's|\.\+\.||g' tmpwhois	#remove multiple periods
			sed -i 's|: |:|g' tmpwhois		#replace colon space with colon
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			regdate=$(grep -m1 -E 'Created:|created:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 -E 'Last updated:|expires:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m2 -E 'Name:|name:' tmpwhois | grep -v 'Domain' | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 -E 'Email Address:|holder email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
					echo "$domain,--,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
					ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
					hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
					echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .ie
		elif grep 'iedr.ie' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			regorg=$(grep -m1 'desc:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			registrar=$(grep -A1 'descr:' tmpwhois | grep -v "$regorg" | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'registration:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'renewal:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .it .at .cz
		elif grep -E 'NIC.AT|nic.it|nic.cz' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			registrar='NIC'
			regdate=$(grep -m1 -E 'Created:|registered:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 -E 'Expire Date:|expire:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -m1 -E 'organization:|Organization:|org:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'e-mail:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .pt
		elif grep 'Titular / Registrant' tmpwhois; then
			sed -i -e 's|^[ \t]*||' tmpwhois	#remove leading white space
			sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			registrar=$(grep -A1 'Tech Contact' tmpwhois | grep -v 'Tech Contact' | sed 's|,||g')
			regdate=$(grep -m1 'Creation Date' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expiration Date' tmpwhois | cut -d':' -f2)
			regorg=$(grep -A1 'Registrant' tmpwhois | grep -v 'Registrant' | sed 's|,||g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .jp
		elif grep 'JPRS' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			sed -i 's|\[||g' tmpwhois		#remove left bracket
			sed -i 's|]|:|g' tmpwhois		#replace right bracket with colon
			regdate=$(grep -m1 'Created on:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expires on:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'Registrant:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .tz
		elif grep 'TZNIC' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			registrar=$(grep -m1 'registrar:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'registred:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'expire:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'org:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'e-mail:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .hk
		elif grep 'HKIRC' tmpwhois; then
			sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			registrar=$(grep -m1 'Registrar Name:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'Domain Name Commencement Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'Expiry Date:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'Company name:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .ru
		elif grep 'RIPN' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			registrar=$(grep -m1 'registrar:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'created:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			regexpdate=$(grep -m1 'paid-till:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			regorg=$(grep -m1 'org:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .dk
		elif grep 'DK Hostmaster' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			regdate=$(grep -m1 'Registered:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expires:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -A2 'Registrant' tmpwhois | grep 'Name:' | cut -d':' -f2 | sed 's|,||g')
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,--,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,--,${regdate}--${regexpdate},$regorg,--,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# NeuStar
		elif grep 'NeuStar' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			registrar=$(grep -m1 'Sponsoring Registrar:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 'Domain Registration Date:' tmpwhois | cut -d':' -f2- | cut -d' ' -f2,3,6 | sed 's| |-|g')
			regexpdate=$(grep -m1 'Domain Expiration Date:' tmpwhois | cut -d':' -f2- | cut -d' ' -f2,3,6 | sed 's| |-|g')
			regorg=$(grep -m1 'Registrant Organization:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .asia
		elif grep 'DotAsia' tmpwhois; then
			registrar=$(grep -m1 'Sponsoring Registrar:|' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 -E 'Domain Create Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'Domain Expiration Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -m1 -E 'Registrant Organization:|Registrant Organisation:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 -E 'Registrant Email:|Registrant E-mail:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .il
		elif grep 'ISOC-IL' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			registrar=$(grep -m1 'registrar name:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regexpdate=$(grep -m1 'validity:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -m1 'descr:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'e-mail:' tmpwhois | sed 's|\ AT\ |\@|' | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,expires:$regexpdate,$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,expires:${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .tw
		elif grep 'ISOC-IL' tmpwhois; then
			sed -i -e 's|^[ \t]*||'	tmpwhois	#remove leading white space
			sed -i 's| \+ |\t|g' tmpwhois		#replace multiple spaces with one
			sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			registrar=$(grep -A2 'Registrant:' tmpwhois | grep '@' | rev | cut -d' ' -f1 | rev)
			regdate=$(grep -m1 'Record created on' tmpwhois | cut -d' ' -f4)
			regexpdate=$(grep -m1 'Record expires on' tmpwhois | cut -d' ' -f4)
			regorg=$(grep -A1 'Registrant:' tmpwhois | grep -v 'Registrant:' | sed 's|,||g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .tr
			sed -i -e 's|^[ \t]*||'	tmpwhois	#remove leading white space
			sed -i 's|\t||g' tmpwhois			#remove tab
			sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			sed -i 's|\.\+\.||g' tmpwhois	#remove multiple periods
			regdate=$(grep -m1 'Created on:' tmpwhois | cut -d':' -f2 | sed 's|\.||')
			regexpdate=$(grep -m1 'Expires on:' tmpwhois | cut -d':' -f2 | sed 's|\.||')
			regorg=$(grep -A1 'Registrant:' tmpwhois | grep -v 'Registrant:' | sed 's|,||g')
			regemail=$(grep -A6 'Registrant:' tmpwhois | grep $emaildomain)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# most .com .net etc
		else
			sed -i -e 's|^[ \t]*||' tmpwhois	#remove leading white space
			sed -i 's| \+ ||g' tmpwhois			#remove multiple spaces
			sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			registrar=$(grep -m1 -E 'Registrar:|Sponsoring Registrar:|' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regdate=$(grep -m1 -E 'Creation Date:|Registration Date:' tmpwhois | cut -d':' -f2 | sed 's|T.*$||g')
			regexpdate=$(grep -m1 -E 'Expiration Date:|Expiry Date:' tmpwhois | cut -d':' -f2 | sed 's|T.*$||g')
			regorg=$(grep -m1 -E 'Registrant Organization:|Registrant Organisation:' tmpwhois | cut -d':' -f2 | sed 's|,||g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | cut -d':' -f2)
			iptmp=$(ping -c1 $domain 2>&1)
			if echo $iptmp | grep -q 'unknown host'; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				ipaddr=$(echo $iptmp | grep 'PING' | cut -d'(' -f2 | cut -d')' -f1)
				hostorg=$(whois $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|,||g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		fi
	fi
	let number=number+1
	echo -ne "\t${GRN}$number ${WHT}of ${GRN}$domcount ${WHT}domains${NC}"\\r

	sleep 2
done < tmpdomainlist

echo
echo -e "${GRN}[*] ${WHT}All finished. Results can be found in ${GRN}$outfile ${WHT}in the current directory.${NC}"
sort -V tmpoutfile | sed 's|111AAA--placeholder--|Domain,Registrar,Create--Exp Date,Registration Org,Reg Email,IP Address,Host Org|' > $outfile

rm tmpcurl1 tmpcurl2 tmpdomainlist tmpwhois tmpoutfile 2>/dev/null