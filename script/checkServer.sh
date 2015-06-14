#!/bin/bash

SERVICEPORT=3000

SYNC_DIR="/home/vagrant/voyagex-synced"
CUR_DIR=`pwd`

echo "PATH=$PATH"

LOGFILE="$SYNC_DIR/log/checkserver.log"

TIMEKEY=`date +%Y-%m-%d\ %H:%M:%S`

if [ -f "service-pid.sh" ] ; then
	SOURCE=true
	. `pwd`/service-pid.sh $SERVICEPORT &>/dev/null

	if [ ! -n "$TPID" ] ; then 
		echo "$TIMEKEY: $SERVICEPORT-service is down. restarting ..." >> "$LOGFILE"
		cd "$SYNC_DIR"
		RAILS_ENV=staging rails s -d
    cd "$CUR_DIR"
	else
    echo "$TIMEKEY: $SERVICEPORT-service is up with pid $TPID" >> "$LOGFILE"
	fi
else
    echo "$TIMEKEY: no service-pid.sh in PATH or in `pwd`" >> "$LOGFILE"
fi

exit 0
