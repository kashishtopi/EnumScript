#!/bin/bash
#Automating_the_Enum
#Use case:- ./Enum.sh test.com

URL=$1

if [ ! -d "$URL" ];
then
	mkdir $URL
fi
if [ ! -d "$URL/recon" ];
then
	mkdir $URL/recon
fi
if [ ! -d "$URL/recon/scans" ];
then
	mkdir $URL/recon/scans
fi
if [ ! -d "$URL/recon/httprobe" ];
then
	mkdir $URL/recon/httprobe
fi
if [ ! -d "$URL/recon/potential_takeovers" ];
then
	mkdir $URL/recon/potential_takeovers
fi
if [ ! -d "$URL/recon/wayback" ];
then
	mkdir $URL/recon/wayback
fi
if [ ! -d "$URL/recon/wayback/params" ];
then
	mkdir $URL/recon/wayback/params
fi
if [ ! -d "$URL/recon/wayback/extensions" ];
then
	mkdir $URL/recon/wayback/extensions
fi
if [ ! -f "$URL/recon/httprobe/alive.txt" ];
then
	touch $URL/recon/httprobe/alive.txt
fi
if [ ! -f "$URL/recon/final.txt" ];
then
	touch $URL/recon/final.txt
fi

echo "[1.0] Harvesting subdomains with Assetfinder ..."
assetfinder --subs-only $URL >> $URL/recon/final.txt

echo "[2.0] Harvesting subdomains with Amass ..."
amass enum -d $URL >> $URL/recon/amass.txt
sort -u $URL/recon/amass.txt >> $URL/recon/final.txt
rm $URL/recon/amass.txt

echo "[3.0] Probing for alive domains..."
cat $URL/recon/final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> $URL/recon/httprobe/temp.txt
sort -u $URL/recon/httprobe/temp.txt >> $URL/recon/httprobe/alive.txt
rm $URL/recon/httprobe/temp.txt

echo "[4.0] Checking for any possible subdomain takeover..."
if [ ! -f "$URL/recon/potential_takeovers/potential_takeovers.txt" ];
then
	touch $URL/recon/potential_takeovers/potential_takeovers.txt
fi

subjack -w $URL/recon/final.txt -t 100 -timeout 30 -ssl -c /usr/share/subjack/fingerprints.json -v 3 -o $URL/recon/potential_takeovers/potential_takeovers.txt

echo "[5.0] Scanning for open ports with nmap..."
nmap -iL $URL/recon/httprobe/alive.txt -T4 -oA $URL/recon/scans/scanned.txt

echo "[6.0] Finding wayback data..."
cat $URL/recon/final.txt | waybackurls >> $URL/recon/wayback/wayback_output.txt
sort -u $URL/recon/wayback/wayback_output.txt

echo "[7.0] Pulling & compiling all possible parameters found in wayback scan..."
cat $URL/recon/wayback/wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> $URL/recon/wayback/params/wayback_params.txt
for line in $(cat $URL/recon/wayback/params/wayback_params.txt);
do 
	echo $line'=';
done

echo "[8.0] Pulling and compiling js/php/aspx/jsp/json files from wayback output..."
for line in $(cat $URL/recon/wayback/wayback_output.txt);
do
	ext="${line##*.}"
	if [[ "$ext" == "js" ]]; then
		echo $line >> $URL/recon/wayback/extensions/js1.txt
		sort -u $URL/recon/wayback/extensions/js1.txt >> $URL/recon/wayback/extensions/js.txt
	fi
	if [[ "$ext" == "html" ]];then
		echo $line >> $URL/recon/wayback/extensions/jsp1.txt
		sort -u $URL/recon/wayback/extensions/jsp1.txt >> $URL/recon/wayback/extensions/jsp.txt
	fi
	if [[ "$ext" == "json" ]];then
		echo $line >> $URL/recon/wayback/extensions/json1.txt
		sort -u $URL/recon/wayback/extensions/json1.txt >> $URL/recon/wayback/extensions/json.txt
	fi
	if [[ "$ext" == "php" ]];then
		echo $line >> $URL/recon/wayback/extensions/php1.txt
		sort -u $URL/recon/wayback/extensions/php1.txt >> $URL/recon/wayback/extensions/php.txt
	fi
	if [[ "$ext" == "aspx" ]];then
		echo $line >> $URL/recon/wayback/extensions/aspx1.txt
		sort -u $URL/recon/wayback/extensions/aspx1.txt >> $URL/recon/wayback/extensions/aspx.txt
	fi
done

rm $URL/recon/wayback/extensions/js1.txt
rm $URL/recon/wayback/extensions/jsp1.txt
rm $URL/recon/wayback/extensions/json1.txt
rm $URL/recon/wayback/extensions/php1.txt
rm $URL/recon/wayback/extensions/aspx1.txt