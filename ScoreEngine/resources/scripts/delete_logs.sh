#!/bin/bash
if [[ $EUID -ne 0 ]] ; then
	echo "You are not smart enough to run this script!"
	exit 1
fi

echo -n "Truncating 'all' files in /var/log/ to size 0..."
find /var/log/ -type f -exec truncate --size 0 "{}" \;

echo -n "Truncating '.viminfo' files in / to size 0..."
find / -iname ".viminfo" -exec truncate --size 0 "{}" \;
echo -n "Truncating '.bash_history' files in / to size 0..."
find / -iname ".bash_history" -exec truncate --size 0 "{}" \;
