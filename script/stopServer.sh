#!/bin/bash

SOURCE=true
if [ ! -n "$1" ] ; then
	typeset -i STOPSERVERPORT=3000
	. `pwd`/service-pid.sh $STOPSERVERPORT
else
	. `pwd`/service-pid.sh "$1"
fi

if [ -n "$TPID" ] ; then 
	echo "======================================"
	echo "killing $PROXYPORT-service-process pid=$TPID"
	echo "======================================"
	kill $TPID
	exit 0
else
	exit 1
fi
