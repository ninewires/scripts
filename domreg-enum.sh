#!/bin/bash

# Script to enumerate domains from client company name & email address domain
#
# Information will then be gathered for each domain, including:
# registrar, creation/expiration dates, registration org, registration email
# IP address, & hosting org
#
# Results will be written to a CSV file
#
# Author: Jason Ashton (ninewires)
# Created: 03/17/2017

GRN='\x1B[1;32m'
WHT='\x1B[1;37m'
RED='\x1B[1;31m'
YEL='\x1B[1;33m'
NC='\x1B[0m'

# Catch termination
trap f_term SIGHUP SIGINT SIGTERM

f_term()
{
echo -e "\n${RED}[!] ${WHT}Caught ${RED}ctrl+c${WHT}, removing all tmp files.${NC}"
rm tmporglist tmpcurl* tmpdomainlist tmpwhois tmpoutfile $outfile 2>/dev/null
exit 1
}

f_sleep()
{
	# randomize sleep interval
	sleeparray=( 1 2 3 4 5 )
	randomsleep=${sleeparray[$RANDOM % ${#sleeparray[@]}]}
	sleep $randomsleep
}

f_uagent()
{
	# user agents to impersonate
	agent1='Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)'
	agent2='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A'
	agent3='Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
	agent4='Mozilla/5.0 (Windows; U; MSIE 9.0; Windows NT 9.0; en-US)'
	agent5='Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20121202 Firefox/17.0 Iceweasel/17.0.1'
	agent6='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36'
	# randomize user agent
	agentarray=( "$agent1" "$agent2" "$agent3" "$agent4" "$agent5" "$agent6" )
	useragent=${agentarray[$RANDOM % ${#agentarray[@]}]}
}

# Get client name
echo -e -n "\nEnter Client Name: "
read -e orgname

# Check client name for null or corp abbr
corpabbr=$(echo $orgname | grep -i -E -o "\b(Co(rp)?\.?|Limited|L\.?(L|T)\.?(D|C|P)\.?|Inc\.?|Assoc\.?)\'")
while [[ $orgname == '' ]] || ! [[ $corpabbr == '' ]]; do
        if [[ $orgname == '' ]]; then
                corpabbr=''
                echo -e -n "\n${RED}[!] ${WHT}Client name is ${RED}empty${WHT}, please try again:${NC} "
                read -e orgname
        fi
        corpabbr=$(echo $orgname | grep -i -E -o "\b(Co(rp)?\.?|Limited|L\.?(L|T)\.?(D|C|P)\.?|Inc\.?|Assoc\.?)\'")
        if ! [[ $corpabbr == '' ]]; then
                echo -e "\n${RED}[!] ${WHT}Client name contains ${RED}$corpabbr${WHT} corporate abbreviation."
                echo -e -n "    Being this specific can limit search results. please try again:${NC} "
                read -e orgname
        fi
done

# Check for names containing '&' or 'and' to search for both instances
if [[ $orgname == *'&'* ]]; then
	echo -e "\n${YEL}[!] ${WHT}Client name contains an ${RED}&${WHT}. We will search for name with ${RED}and ${WHT}also.${NC} "
	echo $orgname | sed "s|[ \']|\+|g; s|-|%2D|g; s|,|%2C|g; s|\.|%2E|g; s|\&|%26|g" > tmporglist
	echo $orgname | sed "s|\&|and|; s|[ \']|\+|g; s|-|%2D|g; s|,|%2C|g; s|\.|%2E|g; s|\&|%26|g" >> tmporglist
elif [[ $orgname == *'and'* ]]; then
	echo -e "\n${YEL}[!] ${WHT}Client name contains ${RED}and${WHT}. We will search for name with an ${RED}& ${WHT}also.${NC}"
	echo $orgname | sed "s|[ \']|\+|g; s|-|%2D|g; s|,|%2C|g; s|\.|%2E|g; s|\&|%26|g" > tmporglist
	echo $orgname | sed "s|and|\&|; s|[ \']|\+|g; s|-|%2D|g; s|,|%2C|g; s|\.|%2E|g; s|\&|%26|g" >> tmporglist
else
	echo $orgname | sed "s|[ \']|\+|g; s|-|%2D|g; s|,|%2C|g; s|\.|%2E|g; s|\&|%26|g" > tmporglist
fi

# Get client email domain
echo -e -n "\nEnter Client Email Domain: "
read -e emaildomain

while ! [[ $emaildomain =~ ^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}$ ]]; do
	echo -e "\n${RED}[!] $emaildomain ${WHT}Is Not Valid Domain Format" >&2
	echo -e -n "Ex: homedepot.com or home-depot.com, Try Again:${NC} "
	read -e emaildomain
done
outfile=$(echo $emaildomain | cut -d'.' -f1 | sed 's|$|_domains.csv|')

# get domains registered by target email address domain
eval f_uagent
curl -s -L --header "Host:viewdns.info" --referer https://viewdns.info --user-agent "$useragent" https://viewdns.info/reversewhois/?q=%40$emaildomain > tmpcurl1
eval f_sleep
eval f_uagent
while read orgnamehtml; do
curl -s -L --header "Host:viewdns.info" --referer https://viewdns.info --user-agent "$useragent" https://viewdns.info/reversewhois/?q=$orgnamehtml >> tmpcurl2
done < tmporglist

if grep 'There are 0 domains' tmpcurl1 && grep 'There are 0 domains' tmpcurl2; then
	echo -e "\n${RED}[!] ${WHT}No ${RED}$emaildomain ${WHT}& ${RED}$orgname ${WHT}not found :-(${NC}"
	rm tmpcurl1 tmpcurl2
	exit 1
elif ! [ -s tmpcurl1 ] && ! [ -s tmpcurl2 ]; then
	echo -e "\n${RED}[!] ${WHT}No ${RED}$emaildomain ${WHT}& ${RED}$orgname ${WHT}not found :-(${NC}"
	rm tmpcurl1 tmpcurl2
	exit 1
elif grep -q 'paymenthash' tmpcurl1; then
	# domain qty exceeds 500 - generate list of domains registered by email address domain - large result count
	echo -e "\n${YEL}[!] ${WHT}More than 500 registered domains. Only first 500 will be listed.${NC}"
	grep 'Domain Name' tmpcurl1 | sed 's|<tr>|\n|g' | grep '</td></tr>' | cut -d'>' -f2 | cut -d'<' -f1 | grep -v 'Domain Name' > tmpdomainlist
	grep 'Domain Name' tmpcurl2 | sed 's|<tr>|\n|g' | grep '</td></tr>' | cut -d'>' -f2 | cut -d'<' -f1 | grep -v 'Domain Name' >> tmpdomainlist
else
	# generate list of domains registered by email address domain
	grep 'ViewDNS.info' tmpcurl1 | sed 's|<tr>|\n|g' | grep '</td></tr>' | grep -v -E 'font size|Domain Name' | cut -d'>' -f2 | cut -d'<' -f1 > tmpdomainlist
	grep 'ViewDNS.info' tmpcurl2 | sed 's|<tr>|\n|g' | grep '</td></tr>' | grep -v -E 'font size|Domain Name' | cut -d'>' -f2 | cut -d'<' -f1 >> tmpdomainlist
fi
sed -i '/^$/d' tmpdomainlist | sort -uV tmpdomainlist -o tmpdomainlist

domcount=$(wc -l tmpdomainlist | sed -e 's|^[ \t]*||' | cut -d' ' -f1)
echo '111AAA--placeholder--' > tmpoutfile
echo -e "\n${GRN}[*] ${WHT}Found ${GRN}$domcount ${WHT}domains for ${GRN}$orgname ${WHT}& ${GRN}$emaildomain${NC}"
echo -e "\n${GRN}[*] ${WHT}A random sleep value of 1-5s will be applied to each whois request to minimize registrar block.${NC}"
echo -e "\n${GRN}[*] ${WHT}Enumerating domain details. . .${NC}"

# loop thru domain list gathering details about the domain
while read domain; do
	eval f_sleep
	whois --verbose -H $domain > tmpwhois 2>/dev/null
	nomatch=$(grep -c -E 'No match for|Name or service not known|NOT FOUND' tmpwhois)
	if [[ $nomatch -eq 1 ]]; then
		echo "$domain, -- No Whois Matches Found" >> tmpoutfile
	else
		# whois server connection refused
		if grep -q -i 'Connection refused' tmpwhois; then
			echo "$domain, -- Whois Server Connection Refused" >> tmpoutfile
		# .au .ae 
		elif grep -q 'A.B.N. SEARCH' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			registrar=$(grep -m1 'Registrar Name:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regorg=$(grep -m1 -E 'Registrant:|Registrant Contact Organisation:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Registrant Contact Email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,--,$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,--,$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .nz - results limited
		elif grep -q 'NZRS' tmpwhois; then
			sed -i 's|: |:|g' tmpwhois		#replace colon space with colon
			registrar=$(grep -m1 'registrar_name:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			moreinfo=$(grep 'Additional information' tmpwhois | cut -d' ' -f8)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,$ipaddr,$hostorg,Additional Info: $moreinfo" >> tmpoutfile
			fi
		# .uk - results limited due to GDPR
		elif grep -q -E 'Copyright Nominet|Using server whois.nic.uk' tmpwhois; then
			sed -i -e 's|^[ \t]*||; s|\s*$||g; s|: \{1,\}|:|g' tmpwhois		#remove leading white space/trailing white space, replace colon white space with colon
			registrar=$(grep -A1 'Registrar:' tmpwhois | grep -v 'Registrar:')
			regdate=$(grep -m1 'Registered on:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expiry date:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'Registrant:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .sg
		elif grep -q 'SGNIC' tmpwhois; then
			sed -i -e 's|^[ \t]*||; s| \+ ||g; s|\t||g; /^$/d' tmpwhois		#remove leading white space/mult spaces/tab/blank lines
			registrar=$(grep -m1 'Registrar:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 'Creation Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'Expiration Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -A1 'Registrant:' tmpwhois | grep 'Name:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .fi .no
		elif grep -q -E 'NORID|Finnish Communications' tmpwhois; then
			sed -i 's|\.\+\.||g; s| \+ ||g; s|: |:|g' tmpwhois		#remove multiple periods/multiple spaces, replace colon space with colon
			regdate=$(grep -m1 -E 'Created:|created:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 -E 'Last updated:|expires:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m2 -E 'Name:|name:' tmpwhois | grep -v 'Domain' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 -E 'Email Address:|holder email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,--,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .ie
		elif grep -q 'iedr.ie' tmpwhois; then
			sed -i 's| \+ ||g; s|: |:|g' tmpwhois		#remove multiple spaces, replace colon space with colon
			regorg=$(grep -m1 'desc:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			registrar=$(grep -A1 'descr:' tmpwhois | grep -v "$regorg" | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 'registration:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'renewal:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .it .at .cz
		elif grep -q -E 'NIC.AT|nic.it|nic.cz' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			registrar='NIC'
			regdate=$(grep -m1 -E 'Created:|registered:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 -E 'Expire Date:|expire:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -m1 -E 'organization:|Organization:|org:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'e-mail:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .pt
		elif grep -q 'Titular / Registrant' tmpwhois; then
			sed -i -e 's|^[ \t]*||, s|: |:|g' tmpwhois		#remove leading white space, replace colon space with colon
			registrar=$(grep -A1 'Tech Contact' tmpwhois | grep -v 'Tech Contact' | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 'Creation Date' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expiration Date' tmpwhois | cut -d':' -f2)
			regorg=$(grep -A1 'Registrant' tmpwhois | grep -v 'Registrant' | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .cn
		elif grep -q 'Using server whois.cnnic.cn' tmpwhois; then
			sed -i -e 's|: |:|g' tmpwhois		#replace colon space with colon
			registrar=$(grep 'Sponsoring Registrar:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 'Registration Time:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expiration Time:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'Registrant:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Registrant Contact Email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registra,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registra,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .jp
		elif grep -q 'JPRS' tmpwhois; then
			sed -i 's| \+ ||g; s|\[||g; s|]|:|g' tmpwhois		#remove multiple spaces/left bracket, right bracket with colon
			regdate=$(grep -m1 'Created on:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expires on:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'Registrant:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,--,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .tz
		elif grep -q 'TZNIC' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			registrar=$(grep -m1 'registrar:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 'registred:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'expire:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'org:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'e-mail:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .hk
		elif grep -q 'HKIRC' tmpwhois; then
			sed -i 's|: |:|g; s| \+ ||g' tmpwhois		#replace colon space with colon, remove multiple spaces
			registrar=$(grep -m1 'Registrar Name:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 'Domain Name Commencement Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'Expiry Date:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -m1 'Company name:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Email:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .ru
		elif grep -q 'RIPN' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			registrar=$(grep -m1 'registrar:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 'created:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			regexpdate=$(grep -m1 'paid-till:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			regorg=$(grep -m1 'org:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,--,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .dk
		elif grep -q 'DK Hostmaster' tmpwhois; then
			sed -i 's| \+ ||g' tmpwhois		#remove multiple spaces
			regdate=$(grep -m1 'Registered:' tmpwhois | cut -d':' -f2)
			regexpdate=$(grep -m1 'Expires:' tmpwhois | cut -d':' -f2)
			regorg=$(grep -A2 'Registrant' tmpwhois | grep 'Name:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,--,${regdate}--${regexpdate},$regorg,--,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,--,${regdate}--${regexpdate},$regorg,--,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# NeuStar .us .biz
		elif grep -q 'NeuStar' tmpwhois; then
			sed -i 's| \+ ||g; s|: |:|g' tmpwhois		#remove multiple spaces. replace colon space with colon
			registrar=$(grep -m1 -E 'Sponsoring Registrar:|Registrar:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			if grep -q 'Creation Date:' tmpwhois; then
				regdate=$(grep -m1 'Creation Date:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			fi
			if grep -q 'Domain Registration Date:' tmpwhois; then
				regdate=$(grep -m1 'Domain Registration Date:' tmpwhois | cut -d':' -f2- | cut -d' ' -f2,3,6 | sed 's| |-|g')
			fi
			if grep -q 'Registry Expiry Date:' tmpwhois; then
				regexpdate=$(grep -m1 'Registry Expiry Date:' tmpwhois | cut -d':' -f2 | cut -d'T' -f1)
			fi
			if grep -q 'Domain Expiration Date:' tmpwhois; then
				regexpdate=$(grep -m1 'Domain Expiration Date:' tmpwhois | cut -d':' -f2- | cut -d' ' -f2,3,6 | sed 's| |-|g')
			fi
			regorg=$(grep -m1 -E 'Registrant Organization:|Registrant Name:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | grep -v -E 'Contact Domain Holder|Please query the RDDS' | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .asia
		elif grep -q 'DotAsia' tmpwhois; then
			registrar=$(grep -m1 -E 'Sponsoring Registrar:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 -E 'Domain Create Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regexpdate=$(grep -m1 'Domain Expiration Date:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -m1 -E 'Registrant Organization:|Registrant Organisation:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 -E 'Registrant Email:|Registrant E-mail:' tmpwhois | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .il
		elif grep -q 'ISOC-IL' tmpwhois; then
			sed -i 's| \+ ||g; s|: |:|g' tmpwhois		#remove multiple spaces, replace colon space with colon
			# sed -i 's|: |:|g' tmpwhois			#replace colon space with colon
			registrar=$(grep -m1 'registrar name:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regexpdate=$(grep -m1 'validity:' tmpwhois | cut -d':' -f2 | cut -d' ' -f1)
			regorg=$(grep -m1 'descr:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'e-mail:' tmpwhois | sed 's|\ AT\ |\@|' | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,expires:$regexpdate,$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,expires:${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .tw
		elif grep -q 'Using server whois.twnic.net.tw' tmpwhois; then
			sed -i -e 's|^[ \t]*||; s| \+ | |g; s|: |:|g' tmpwhois		#remove leading white space, replace mult spaces with one/colon space with space
			registrar=$(grep 'Registration Service Provider:' tmpwhois | cut -d':' -f2)
			regdate=$(grep -m1 'Record created on' tmpwhois | cut -d' ' -f4)
			regexpdate=$(grep -m1 'Record expires on' tmpwhois | cut -d' ' -f4)
			regorg=$(grep -A1 'Registrant:' tmpwhois | grep -v 'Registrant:' | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -A2 'Registrant:' tmpwhois | grep '@' | rev | cut -d' ' -f1 | rev)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .tr
		elif grep -q 'Using server whois.nic.tr' tmpwhois; then
			sed -i 's|\t| |g; s|^ \+||g; s| \+ ||g; s|: |:|g'	tmpwhois		#remove leading white space, replace mult space colon with colon
			registrar=$(grep -A2 'Registrar:' tmpwhois | grep 'Organization Name:' | cut -d':' -f2)
			regdate=$(grep -m1 'Created on' tmpwhois | cut -d':' -f2 | sed 's|\.||')
			regexpdate=$(grep -m1 'Expires on' tmpwhois | cut -d':' -f2 | sed 's|\.||')
			regorg=$(grep -A1 'Registrant:' tmpwhois | grep -v 'Registrant:' | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -A6 'Registrant:' tmpwhois | grep '@')
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		# .com .net .org etc
		else
			sed -i -e 's|^[ \t]*||; s| \+ ||g; s|: |:|g' tmpwhois		#remove leading white space; mult spaces, replace colon space with colon
			registrar=$(grep -m1 -E 'Registrar:|Sponsoring Registrar:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regdate=$(grep -m1 -E 'Creation Date:|Registration Date:' tmpwhois | cut -d':' -f2 | sed 's|T.*$||g')
			regexpdate=$(grep -m1 -E 'Expiration Date:|Expiry Date:' tmpwhois | cut -d':' -f2 | sed 's|T.*$||g')
			regorg=$(grep -m1 -E 'Registrant Organization:|Registrant Organisation:' tmpwhois | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
			regemail=$(grep -m1 'Registrant Email:' tmpwhois | grep -v -E 'Contact Domain Holder|Please query the RDDS' | cut -d':' -f2)
			ipaddr=$(dig @8.8.8.8 +short $domain | cut -d$'\n' -f1 2>&1)
			if [[ $ipaddr == "" ]]; then
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,No IP Found,No Host Org Found" >> tmpoutfile
			else
				hostorg=$(whois --verbose -H $ipaddr 2>&1 | sed 's| \+ ||g' | grep -m1 -E 'Organization|address:' | cut -d':' -f2 | sed 's|^|"|g; s|$|"|g')
				echo "$domain,$registrar,${regdate}--${regexpdate},$regorg,$regemail,$ipaddr,$hostorg" >> tmpoutfile
			fi
		fi
	fi
	let number=number+1
	echo -ne "\t${GRN}$number ${WHT}of ${GRN}$domcount ${WHT}domains${NC}"\\r

	sleep 2
done < tmpdomainlist

sort -V tmpoutfile | sed 's|111AAA--placeholder--|Domain,Registrar,Create--Exp Date,Registration Org,Reg Email,IP Address,Host Org|' > $outfile
echo -e "\n${GRN}[*] ${WHT}All finished. Results can be found in ${GRN}$outfile ${WHT}in the current directory.${NC}"

rm tmporglist tmpcurl* tmpdomainlist tmpwhois tmpoutfile 2>/dev/null
