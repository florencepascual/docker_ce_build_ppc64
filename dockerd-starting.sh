#!/bin/bash

echo "Waiting for dockerd to start"
TIMEOUT=10
DAEMON="dockerd"
i=0
echo $TIMEOUT
echo $DAEMON
echo $i
while [ $i -lt $TIMEOUT ] && ! /usr/bin/pgrep $DAEMON
do
    i=$((i+1))
    echo $i
    sleep 2
done

pid=`/usr/bin/pgrep $DAEMON`
echo $pid


if [ -z "$pid" ]
then
    echo "$DAEMON has not started after $(($TIMEOUT*2)) seconds"
    exit 1
else
    echo "Found $DAEMON pid:$pid"
    ps -aef | grep docker | grep -v grep
    sleep 10
    ps -aef
    echo "Launching docker info"
    docker info
fi