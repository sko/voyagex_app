#!/bin/bash

PROXYPORT="$1"

if [ ! -n "$PROXYPORT" ] ; then
	echo ""
	echo "Usage: $0 \$proxyport"
	echo ""
	exit 1
fi

LINE=`netstat -antp | grep ":$PROXYPORT"`
if [ -z "$LINE" ] ; then 
	echo "======================================"
	echo "no :$PROXYPORT-service-process found"
	echo "======================================"
	if [ ! -n "$SOURCE" ] ; then
		exit 1
	fi
else
	TPID=`echo "$LINE" | grep -o "LISTEN.*[0-9]" | grep -o "[0-9].*"` 
	if [ -n "$TPID" ] ; then 
		echo "======================================"
		echo "$LINE" | grep LISTEN  
		echo "--------------------------------------"
		echo ":$PROXYPORT-service-process-pid = $TPID"
		echo "======================================"
		export TPID
		if [ ! -n "$SOURCE" ] ; then
			exit 0
		fi
	else
		echo "======================================"
		echo "$LINE" | grep LISTEN 
		echo "--------------------------------------"
		echo "no pid-info available for :$PROXYPORT-service-process"
		echo "======================================"
		if [ ! -n "$SOURCE" ] ; then
			exit 1
		fi
	fi
fi
 
