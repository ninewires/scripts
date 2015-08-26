#!/bin/bash
# Updated 12/17/2011

##################################################
# Catch ctrl-c input from user
trap f_Proc_Killer 2

##################################################
f_PreviousMenu(){
echo ""
}

##################################################
f_Proc_Killer(){
bash $0
kill $$ > /dev/null 2>&1
killall -9 nmap > /dev/null
}

##################################################
f_Error(){
echo "Invalid Input.  Please try again"
sleep 3
}

##################################################
f_WrongPath(){
echo "Invalid Path.  Please try again"
sleep 3
}

##################################################
f_Banner(){
cat << !

########  ####  ######   ######   #######  ##     ## ######## ########  
##     ##  ##  ##    ## ##    ## ##     ## ##     ## ##       ##     ## 
##     ##  ##  ##       ##       ##     ## ##     ## ##       ##     ## 
##     ##  ##   ######  ##       ##     ## ##     ## ######   ########  
##     ##  ##        ## ##       ##     ##  ##   ##  ##       ##   ##   
##     ##  ##  ##    ## ##    ## ##     ##   ## ##   ##       ##    ##  
########  ####  ######   ######   #######     ###    ######## ##     ##

This script leverages nmap and its scripts for discovery and enumeration during a pen test.
*** At any time, ctrl+c to kill the scan and return to main menu ***

!
}

##################################################
f_Discovery(){
START=$(date +%H:%M:%S)

mkdir -p $name
echo
echo "#########################"
echo
echo "Looking for hosts"

nmap --scan-delay 3s -g 88 -PP -PE -PM -PI -PA20,53,80,113,443,5060,10043 --max-retries=2 --stats-every 30s -PS1,7,9,13,21-23,25,37,42,49,53,69,79-81,105,109-111,113,123,135,137-139,143,161,179,222,384,389,407,443,445,465,500,512-515,523,540,548,554,587,617,623,689,705,783,910,912,921,993,995,1000,1024,1100,1158,1220,1300,1311,1352,1433-1435,1494,1521,1533,1581-1582,1604,1720,1723,1755,1900,2000,2049,2100,2103,2121,2207,2222,2323,2380,2525,2533,2598,2638,2947,2967,3000,3050,3057,3128,3306,3389,3500,3628,3632,3690,3780,3790,4000,4445,5051,5060-5061,5093,5168,5250,5353,5400,5405,5432-5433,5554-5555,5800,5900-5910,6000,6050,6060,6070,6101,6106,6112,6405,6502-6504,6660,6667,7080,7144,7210,7510,7777,7787,8000,8008,8028,8030,8080-8081,8090,8180,8222,8300,8333,8400,8443-8444,8800,8812,8880,8888,8899,9080-9081,9090,9111,9152,9999-10000,10050,10202-10203,10443,10616,10628,11000,12174,12203,13500,14330,17185,18881,19300,19810,20031,20222,22222,25000,25025,26000,26122,28222,30000,38292,41025,41523-41524,44334,50000-50004,50013,57772,62078,62514,65535 -PU59428 -iL $location  -sSV -sUV --open --version-intensity 0 -pU:53,67-69,111,123,135,137,138,139,161-162,445,500,514,520,631,998,1434,1701,1900,4500,5353,49152,49154,T:1,7,9,13,21-23,25,37,42,49,53,69,79-81,105,109-111,113,123,135,137-139,143,161,179,222,384,389,407,443,445,465,500,512-515,523,540,548,554,587,617,623,689,705,783,910,912,921,993,995,1000,1024,1100,1158,1220,1300,1311,1352,1433-1435,1494,1521,1533,1581-1582,1604,1720,1723,1755,1900,2000,2049,2100,2103,2121,2207,2222,2323,2380,2525,2533,2598,2638,2947,2967,3000,3050,3057,3128,3306,3389,3500,3628,3632,3690,3780,3790,4000,4445,5051,5060-5061,5093,5168,5250,5353,5400,5405,5432-5433,5554-5555,5800,5900-5910,6000,6050,6060,6070,6101,6106,6112,6405,6502-6504,6660,6667,7080,7144,7210,7510,7777,7787,8000,8008,8028,8030,8080-8081,8090,8180,8222,8300,8333,8400,8443-8444,8800,8812,8880,8888,8899,9080-9081,9090,9111,9152,9999-10000,10050,10202-10203,10443,10616,10628,11000,12174,12203,13500,14330,17185,18881,19300,19810,20031,20222,22222,25000,25025,26000,26122,28222,30000,38292,41025,41523-41524,44334,50000-50004,50013,57772,62078,62514,65535 -oA /tmp/discovery

# Get IPs out of the scan info
cat /tmp/discovery.gnmap | cut -d' ' -f2,4 | cut -d' ' -f1 | grep ^[0-9]|sort -u > $name/scan
}

##################################################
f_DiscoveryExclude(){
START=$(date +%H:%M:%S)

mkdir -p $name
echo
echo "#########################"
echo
echo "Looking for hosts"

nmap --excludefile $excludefile --scan-delay 3s -g 88 -PP -PE -PM -PI -PA20,53,80,113,443,5060,10043 --stats-every 30s -PS1,7,9,13,21-23,25,37,42,49,53,69,79-81,105,109-111,113,123,135,137-139,143,161,179,222,384,389,407,443,445,465,500,512-515,523,540,548,554,587,617,623,689,705,783,910,912,921,993,995,1000,1024,1100,1158,1220,1300,1311,1352,1433-1435,1494,1521,1533,1581-1582,1604,1720,1723,1755,1900,2000,2049,2100,2103,2121,2207,2222,2323,2380,2525,2533,2598,2638,2947,2967,3000,3050,3057,3128,3306,3389,3500,3628,3632,3690,3780,3790,4000,4445,5051,5060-5061,5093,5168,5250,5353,5400,5405,5432-5433,5554-5555,5800,5900-5910,6000,6050,6060,6070,6101,6106,6112,6405,6502-6504,6660,6667,7080,7144,7210,7510,7777,7787,8000,8008,8028,8030,8080-8081,8090,8180,8222,8300,8333,8400,8443-8444,8800,8812,8880,8888,8899,9080-9081,9090,9111,9152,9999-10000,10050,10202-10203,10443,10616,10628,11000,12174,12203,13500,14330,17185,18881,19300,19810,20031,20222,22222,25000,25025,26000,26122,28222,30000,38292,41025,41523-41524,44334,50000-50004,50013,57772,62078,62514,65535 -PU59428 -iL $location  -sSV -sUV --open --version-intensity 0 -pU:53,67-69,111,123,135,137,138,139,161-162,445,500,514,520,631,998,1434,1701,1900,4500,5353,49152,49154,T:1,7,9,13,21-23,25,37,42,49,53,69,79-81,105,109-111,113,123,135,137-139,143,161,179,222,384,389,407,443,445,465,500,512-515,523,540,548,554,587,617,623,689,705,783,910,912,921,993,995,1000,1024,1100,1158,1220,1300,1311,1352,1433-1435,1494,1521,1533,1581-1582,1604,1720,1723,1755,1900,2000,2049,2100,2103,2121,2207,2222,2323,2380,2525,2533,2598,2638,2947,2967,3000,3050,3057,3128,3306,3389,3500,3628,3632,3690,3780,3790,4000,4445,5051,5060-5061,5093,5168,5250,5353,5400,5405,5432-5433,5554-5555,5800,5900-5910,6000,6050,6060,6070,6101,6106,6112,6405,6502-6504,6660,6667,7080,7144,7210,7510,7777,7787,8000,8008,8028,8030,8080-8081,8090,8180,8222,8300,8333,8400,8443-8444,8800,8812,8880,8888,8899,9080-9081,9090,9111,9152,9999-10000,10050,10202-10203,10443,10616,10628,11000,12174,12203,13500,14330,17185,18881,19300,19810,20031,20222,22222,25000,25025,26000,26122,28222,30000,38292,41025,41523-41524,44334,50000-50004,50013,57772,62078,62514,65535 -oA /tmp/discovery

# Get IPs out of the scan info
cat /tmp/discovery.gnmap | cut -d' ' -f2,4 | cut -d' ' -f1 | grep ^[0-9]|sort -u > $name/scan
}

##################################################
f_NmapCleanup(){

# Clean up nmap output
cat /tmp/discovery.nmap | egrep -v '(All|filtered|"fingerprint not ideal"|initiated|latency|NEXT|"No OS matches"|Not|Please|scanned|SF|Skipping|unrecognized|Warning|"Service Info")' > $name/tmp
sed 's/Nmap scan report for//' $name/tmp > $name/tmp2
sed 's/^[ \t]*//' $name/tmp2 > $name/nmap.txt
mv /tmp/discovery.xml $name/nmap.xml

# Show open ports
cat $name/nmap.txt | grep / | awk '{print $1}' | sort -u| sort -n > $name/ports.txt
cat $name/ports.txt |grep tcp > $name/tcp-ports.txt
cat $name/ports.txt |grep udp > $name/udp-ports.txt

# Clean up and show banners
cat $name/nmap.txt | egrep '(tcp|udp)' | awk '{for (i=4;i<=NF;i++) {printf "%s%s",sep, $i;sep=" "}; printf "\n"}' | sort -u > $name/tmp
sed 's/^ //' $name/tmp | sort -u > $name/tmp2

# remove blank lines
sed '/^$/d' $name/tmp2 > $name/banners.txt

# Combine web port IPs and sort
cat $name/80.txt $name/443.txt $name/8000.txt $name/8080.txt $name/8443.txt > $name/tmp
sort -u -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 $name/tmp > $name/web.txt

# Combine x11 IPs and sort
cat $name/6000.txt $name/6001.txt $name/6002.txt $name/6003.txt $name/6004.txt $name/6005.txt > $name/tmp
sort -u -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 $name/tmp > $name/x11.txt

# Combine smb port IPs and sort
cat $name/139.txt $name/445.txt > $name/tmp
sort -u -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 $name/tmp > $name/smb.txt

# Combine mssql port IPs and sort
cat $name/1433.txt $name/1434.txt > $name/tmp
sort -u -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 $name/tmp > $name/mssql.txt

# Remove all empty files
find $name/ -type f -empty -exec rm {} +
}

##################################################
f_NmapPorts(){
# TCP ports
echo
echo "Finding TCP ports of discovered hosts"
TCP_PORTS="21 22 23 25 79 80 110 111 139 143 389 443 445 548 993 995 1433 1521 3306 3389 5900 6000 6001 6002 6003 6004 6005 8000 8080 8443 9100"
for i in $TCP_PORTS; do
echo "     $i"
cat /tmp/discovery.gnmap | grep "\<$i/open/tcp\>" |cut -d" " -f2 > $name/$i.txt
done
# UDP ports
echo
echo "Finding UDP ports of discovered hosts"
UDP_PORTS="53 67 123 137 161 1434 1604"
for i in $UDP_PORTS; do
echo "     $i"
cat /tmp/discovery.gnmap | grep "\<$i/open/udp\>" |cut -d" " -f2 > $name/$i.txt
done
}

##################################################
f_NmapScripts(){
echo
echo "#########################"
echo
echo "Running service specific nmap scripts"
echo
echo "#########################"
# If the file for the corresponding port doesn't exist, skip

if [ -f $name/21.txt ]; then
	echo "     FTP"
	nmap -iL $name/21.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p21 --script=banner,ftp-anon,ftp-bounce > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-21.txt
fi

if [ -f $name/22.txt ]; then
	echo "     SSH"
	nmap -iL $name/22.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p22 --script=sshv1,ssh2-enum-algos  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-22.txt
fi

if [ -f $name/23.txt ]; then
	echo "     Telnet"
	nmap -iL $name/23.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p23 -sC --script=banner  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-23.txt
fi

if [ -f $name/25.txt ]; then
	echo "     SMTP"
	nmap -iL $name/25.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p25 --script=banner,smtp-commands,smtp-enum-users,smtp-open-relay,smtp-strangeport  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|Couldn|failed|"Service Info"|"detection performed")' > $name/script-25.txt
fi

if [ -f $name/53.txt ]; then
	echo "     DNS"
	nmap -iL $name/53.txt -Pn -n --scan-delay 3s -g 88 -sS -sU --open -p53 --script=dns-cache-snoop,dns-service-discovery,dns-update,dns-zone-transfer,dns-recursion  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|error|impervious|"0 of 100"|"detection performed")' > $name/script-53.txt
fi

if [ -f $name/67.txt ]; then
	echo "     DHCP"
	nmap -iL $name/67.txt -Pn -n --scan-delay 3s -g 88 -sS -sU --open -p67 -sC  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|error|impervious|"Service Info")' > $name/script-67.txt
fi

if [ -f $name/110.txt ]; then
	echo "     POP3"
	nmap -iL $name/110.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p110 --script=banner,pop3-capabilities  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service Info")' > $name/script-110.txt
fi

if [ -f $name/111.txt ]; then
	echo "     NFS"
	nmap -iL $name/111.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p111 --script=rpcinfo,nfs-ls,nfs-showmount,nfs-statfs > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service Info")' > $name/script-111.txt
fi

if [ -f $name/123.txt ]; then
	echo "     NTP"
	nmap -iL $name/123.txt -Pn -n --scan-delay 3s -g 88 -sS -sU --open -p123 --script=ntp-info,ntp-monlist  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service Info")' > $name/script-123.txt
fi

if [ -f $name/137.txt ]; then
	echo "     NetBIOS"
	nmap -iL $name/137.txt -Pn -n --scan-delay 3s -g 88 -sS -sU --open -p137 --script=nbstat  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service Info")' > $name/script-137.txt
fi

if [ -f $name/smb.txt ]; then
	echo "     SMB"
	nmap -iL $name/smb.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p139,445 --script="smb-enum*",smb-os-discovery,smb-security-mode,smb-server-stats,smb-system-info,smbv2-enabled,smb-check-vulns  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service Info")' > $name/script-smb.txt
fi

if [ -f $name/143.txt ]; then
	echo "     IMAP"
	nmap -iL $name/143.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p143 --script=imap-capabilities  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service Info")' > $name/script-143.txt
fi

if [ -f $name/161.txt ]; then
	echo "     SNMP"
	nmap -iL $name/161.txt -Pn -n --scan-delay 3s -g 88 -sS -sU --open -p161 --script=snmp-interfaces  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|TIMEOUT|"Service Info")' > $name/script-161.txt
fi

if [ -f $name/389.txt ]; then
	echo "     LDAP"
	nmap -iL $name/389.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p389 --script=ldap-rootdse  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service Info")' > $name/script-389.txt
fi

if [ -f $name/443.txt ]; then
	echo "     SSL"
	nmap -iL $name/443.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p443 --script=banner,ssl-cert,ssl-enum-ciphers,sslv2  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|unrecognized|SF|servicefp|"Service Info")' > $name/script-443.txt
fi

if [ -f $name/548.txt ]; then
	echo "     AFP"
	nmap -iL $name/548.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p548 --script=afp-serverinfo,afp-showmount  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-548.txt
fi

if [ -f $name/993.txt ]; then
	echo "     SSL/IMAP"
	nmap -iL $name/993.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p993 --script=banner,sslv2,imap-capabilities  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds|"Service detection")' > $name/script-993.txt
fi

if [ -f $name/995.txt ]; then
	echo "     SSL/POP3"
	nmap -iL $name/995.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p995 --script=banner,sslv2,pop3-capabilities  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-995.txt
fi

if [ -f $name/mssql.txt ]; then
	echo "     MS-SQL"
	nmap -iL $name/mssql.txt -Pn -n --scan-delay 3s -g 88 -sS -sUV --open -p T:1433,U:1434 --script=ms-sql-info,ms-sql-empty-password --script ms-sql-tables --script-args mssql.username=sa,mssql.password=password  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-mssql.txt
fi

if [ -f $name/1521.txt ]; then
	echo "     Oracle"
	nmap -iL $name/1521.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p1521 --script=oracle-sid-brute  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-1521.txt
fi
if [ -f $name/1604.txt ]; then
	echo "     CITRIX"
	nmap -iL $name/1604.txt -Pn -n --scan-delay 3s -g 88 -sS -sU --open -p1604 --script=citrix-enum-apps,citrix-enum-servers  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-1604.txt
fi
if [ -f $name/3306.txt ]; then
	echo "     MYSQL"
	nmap -iL $name/3306.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p3306 --script=mysql-databases,mysql-info,mysql-users,mysql-variables  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-3306.txt
fi

if [ -f $name/5900.txt ]; then
	echo "     VNC"
	nmap -iL $name/5900.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p5900 --script=vnc-info,realvnc-auth-bypass  > $name/tmp
	cat $name/tmp | egrep -v '(Starting|latency|seconds)' > $name/script-5900.txt
fi

if [ -f $name/x11.txt ]; then
	echo "     X11"
	nmap -iL $name/x11.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p6000-6005 --script=x11-access > $name/tmp
	cat $name/tmp |egrep -v '(#|latency|filtered)' > $name/script-x11.txt
fi

if [ -f $name/web.txt ]; then
	echo "     WEB"
	nmap -iL $name/web.txt -Pn -n --scan-delay 3s -g 88 -sS --open -p80,443,8000,8080,8443 --script=http-date,http-enum,http-favicon,http-headers,http-open-proxy,http-php-version,http-robots.txt,http-title,http-trace,http-vhosts,http-vmware-path-vuln,citrix-enum-apps-xml,citrix-enum-servers-xml --stats-every 30s -oN /tmp/web
	cat /tmp/web |egrep -v '(#|latency|filtered|Starting|seconds|unrecognized|SF|servicefp|Service|FINGERPRINT)' > $name/script-web.txt
fi

echo
rm $name/tmp*
}
##################################################
f_ScanName(){
echo
echo -n "Name of scan: "
read -e name

if [ -z $name ]; then
	f_Error
	f_ScanName
fi
}
##################################################

f_SingleHost(){
clear
f_Banner
f_ScanName
echo
echo -n "IP address: "
read -e ip

# Check for no answer
if [ -z $ip ]; then
	f_Error
	f_SingleHost
fi

echo $ip > /tmp/list
location=/tmp/list
f_Discovery
f_NumHosts
f_NmapPorts
f_NmapCleanup
f_NmapScripts
f_Generate
}
##################################################

f_ListHosts(){
clear
f_Banner
f_ScanName
echo
echo -n "Please enter the location of your IP list: "
read -e location

# Check for no answer
if [ -z $location ]; then
	f_Error
	f_ListHosts
fi

# Check for wrong answer
if [ ! -f $location ]; then
	f_Error
	f_ListHosts
fi
echo
echo -n "Do you have an exclusion list? (y/N) "
read -e ExFile

if [ -z $ExFile ]; then
	ExFile="n"
fi

ExFile="$(echo ${ExFile} | tr 'A-Z' 'a-z')"

if [ $ExFile == "y" ]; then
	echo -n "Enter the path to the exclude list file: "
	read -e excludefile

	if [ -z $excludefile ]; then
		f_Error
		f_ListHosts
	fi
	if [ ! -f $excludefile ]; then
		f_WrongPath
		f_ListHosts
	fi
	f_DiscoveryExclude
else
	f_Discovery
fi
f_NumHosts
f_NmapPorts
f_NmapCleanup
f_NmapScripts
f_Generate
}
##################################################

f_CidrRange(){
clear
f_Banner
f_ScanName

echo
echo Usage: 192.168.0.0/16
echo
echo -n "Please enter your CIDR Range: "
read -e cidr

# Check for no answer
if [ -z $cidr ]; then
	f_Error
	f_CidrRange
fi

#Check for wrong answer

sub=$(echo $cidr|cut -d '/' -f2)
max=32
if [ "$sub" -gt "$max" ]; then
	f_Error
	f_CidrRange
fi

echo $cidr | grep '/' > /dev/null
if [ $? -ne 0 ]; then
	f_Error
	f_CidrRange
fi

echo $cidr | grep [[:alpha:]\|[,\\]] > /dev/null

if [ $? -eq 0 ]; then
	f_Error
	f_CidrRange
fi

echo $cidr > /tmp/list
location=/tmp/list
echo
echo -n "Do you have an exclusion list? (y/N) "
read -e ExFile

if [ -z $ExFile ]; then
	ExFile="n"
fi

ExFile="$(echo ${ExFile} | tr 'A-Z' 'a-z')"

if [ $ExFile == "y" ]; then
	echo -n "Enter the path to the exclude list file: "
	read -e excludefile

	if [ -z $excludefile ]; then
		f_Error
		f_CidrRange
	fi
	if [ ! -f $excludefile ]; then
		f_WrongPath
		f_CidrRange
	fi
	f_DiscoveryExclude

else
	f_Discovery
fi
f_NumHosts
f_NmapPorts
f_NmapCleanup
f_NmapScripts
f_Generate
}

##################################################
f_ListHostsDiscOnly(){
clear
f_Banner
f_ScanName
echo
echo -n "Please enter the location of your IP list: "
read -e location

# Check for no answer
if [ -z $location ]; then
	f_Error
	f_ListHostsDiscOnly
fi

# Check for wrong answer
if [ ! -f $location ]; then
	f_Error
	f_ListHostsDiscOnly
fi
echo
echo -n "Do you have an exclusion list? (y/N) "
read -e ExFile

if [ -z $ExFile ]; then
	ExFile="n"
fi

ExFile="$(echo ${ExFile} | tr 'A-Z' 'a-z')"

if [ $ExFile == "y" ]; then
	echo -n "Enter the path to the exclude list file: "
	read -e excludefile

	if [ -z $excludefile ]; then
		f_Error
		f_ListHostsDiscOnly
	fi
	if [ ! -f $excludefile ]; then
		f_WrongPath
		f_ListHostsDiscOnly
	fi
	f_DiscoveryExclude
else
	f_Discovery
fi
f_NumHosts
f_HostOnlyGenerate
}

##################################################
f_CidrRangeDiscOnly(){
clear
f_Banner
f_ScanName

echo
echo Usage: 192.168.0.0/16
echo
echo -n "Please enter your CIDR Range: "
read -e cidr

# Check for no answer
if [ -z $cidr ]; then
	f_Error
	f_CidrRangeDiscOnly
fi

#Check for wrong answer

sub=$(echo $cidr|cut -d '/' -f2)
max=32
if [ "$sub" -gt "$max" ]; then
	f_Error
	f_CidrRangeDiscOnly
fi

echo $cidr | grep '/' > /dev/null
if [ $? -ne 0 ]; then
	f_Error
	f_CidrRangeDiscOnly
fi

echo $cidr | grep [[:alpha:]\|[,\\]] > /dev/null

if [ $? -eq 0 ]; then
	f_Error
	f_CidrRangeDiscOnly
fi

echo $cidr > /tmp/list
location=/tmp/list
echo
echo -n "Do you have an exclusion list? (y/N) "
read -e ExFile

if [ -z $ExFile ]; then
	ExFile="n"
fi

ExFile="$(echo ${ExFile} | tr 'A-Z' 'a-z')"

if [ $ExFile == "y" ]; then
	echo -n "Enter the path to the exclude list file: "
	read -e excludefile

	if [ -z $excludefile ]; then
		f_Error
		f_CidrRangeDiscOnly
	fi
	if [ ! -f $excludefile ]; then
		f_WrongPath
		f_CidrRangeDiscOnly
	fi
	f_DiscoveryExclude

else
	f_Discovery
fi
f_NumHosts
f_HostOnlyGenerate
}

##################################################
f_HostOnlyGenerate(){
echo
echo "Now generating your host-only report..."
filename=$name/$name-report.txt
echo "Host-Only Report" > $filename
echo "$name" >> $filename
date >> $filename
if [ ! -s $name/list.txt ]; then
	echo "No hosts found."
	sleep 3
	f_Proc_Killer
	rm $filename
else
	host=`wc -l $name/list.txt | cut -d " " -f1`
fi
if [ $host -eq 1 ]; then
	echo $break >> $filename
	echo >> $filename
	echo "1 host discovered." >> $filename
	echo >> $filename
else
	echo $break >> $filename
	echo >> $filename
	echo "Hosts Discovered ($host)" >> $filename
	echo >> $filename
	cat $name/list.txt >> $filename
fi
echo
echo "Your host-only report has been created as $name-report.txt in the $name directory."
sleep 5
rm $name/tmp*
mv $name/list.txt $name/hosts.txt
}

##################################################
f_NumHosts(){
# Check for zero hosts (empty file)
if [ ! -s $name/scan ] ; then
	echo
	echo "Sorry, Discover found no hosts."
	echo
	echo "Returning to main menu."
	sleep 5
	rm -rf "$name"
	f_Proc_Killer
fi

# Sort IP address list
sort -u -n -t. -k 1,1 -k2,2 -k3,3 -k4,4 $name/scan > $name/scan2

# remove blank lines
sed '/^$/d' $name/scan2 > $name/list.txt

# Total number of hosts
NUMBER=`wc -l $name/list.txt | cut -d " " -f1`
COUNT=0

if [ $NUMBER -eq 1 ]; then
echo
echo "Host discovered."
echo
else
echo "$NUMBER hosts discovered."
echo
echo "#########################"
fi
}

##################################################
f_Generate(){
END=$(date +%H:%M:%S)
scannerip=$(ifconfig | grep Bcast| cut -d ":" -f2|cut -d" " -f1)
scannerhost=$(uname -n)
filename=$name/$name-report.txt
break="####################################"
echo "Now generating your technical report..."
echo "Technical Report" > $filename
echo "$name" >> $filename
date >> $filename
echo >> $filename
nmap -V | grep version|cut -d" " -f1-3 >> $filename
echo >> $filename
echo "Scanner hostname - $scannerhost" >> $filename
echo "Scanner ip - $scannerip" >> $filename
echo >> $filename
echo "Scan started at $START" >> $filename
echo "Scan finished at $END" >> $filename
echo >> $filename

# Total number of...
if [ ! -s $name/list.txt ]; then
	echo "No hosts found."
	sleep 3
	f_Proc_Killer
	rm $filename
else
	host=`wc -l $name/list.txt | cut -d " " -f1`
fi

if [ ! -s $name/ports.txt ]; then
	echo "No open ports found."
	sleep 3
	#rm $filename
	f_Proc_Killer
else
	ports=`wc -l $name/ports.txt | cut -d " " -f1`
fi

if [ $host -eq 1 ]; then
	echo $break >> $filename
	echo >> $filename
	echo "1 host discovered." >> $filename
	echo >> $filename
	f_GenerateScripts
else
	echo $break >> $filename
	echo >> $filename
	echo "Hosts Discovered ($host)" >> $filename
	echo >> $filename
	cat $name/list.txt >> $filename
	f_GenerateScripts
fi
}
##################################################
f_GenerateScripts(){
echo $break >> $filename
echo >> $filename
echo "Open Ports ($ports)" >> $filename
echo >> $filename
echo "TCP Ports" >> $filename
cat $name/tcp-ports.txt >> $filename

if [ -s $name/udp-ports.txt ]; then
	echo >> $filename
	echo "UDP Ports" >> $filename
	cat $name/udp-ports.txt >> $filename
	echo $break >> $filename
fi

if [ -f $name/banners.txt ]; then
	banners=`wc -l $name/banners.txt | cut -d " " -f1`
	echo >> $filename
	echo "Banners ($banners)" >> $filename
	echo >> $filename
	cat $name/banners.txt >> $filename
	echo >> $filename
	echo $break >> $filename
fi

echo >> $filename
echo "High Value Ports by Host" >> $filename
echo >> $filename

HVPORTS="21 22 23 25 53 67 80 110 111 123 135 137 139 143 161 389 443 445 548 993 995 1433 1521 3306 3389 5900 8000 8080 8443 9100"

for i in $HVPORTS; do
	if [ -f $name/$i.txt ]; then
    	echo "Port $i" >> $filename
    	cat $name/$i.txt >> $filename
    	echo >> $filename
	fi
done

echo $break >> $filename
echo >> $filename
echo "Nmap Service Scripts" >> $filename
echo >> $filename

SCRIPTS="script-21 script-22 script-23 script-25 script-53 script-67 script-110 script-111 script-123 script-137 script-smb script-143 script-161 script-389 script-443 script-548 script-993 script-995 script-mssql script-1521 script-1604 script-3306 script-5900 script-x11 script-web"

for i in $SCRIPTS; do
	if [ -f $name/"$i.txt" ]; then
	cat $name/"$i.txt" >> $filename
	echo $break >> $filename
	fi
done

echo >> $filename
cat $name/nmap.txt >> $filename
echo
echo "Your technical report has been created as $name-report.txt in the $name directory."
sleep 5
mv $name/list.txt $name/hosts.txt
START=0
END=0
}
##################################################

f_HostDiscOnlyMenu(){
clear
f_Banner

cat << !
1.  List of Hosts
2.  CIDR Range
3.  Previous Menu
!
echo
echo -n "Choice: "
read choice

case $choice in
1) f_ListHostsDiscOnly ;;
2) f_CidrRangeDiscOnly ;;
3) f_PreviousMenu ;;

*) f_Error;;

esac
}

##################################################

while : # Loop forever
do

clear
f_Banner

cat << !
1.  Single Host
2.  List of Hosts
3.  CIDR Range
4.  Host Discovery Only
5.  Exit
!

echo
echo -n "Choice: "
read choice

case $choice in
1) f_SingleHost;;
2) f_ListHosts;;
3) f_CidrRange;;
4) f_HostDiscOnlyMenu;;
5)  clear && exit;;

*) f_Error;;

esac

done

