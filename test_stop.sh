#!/bin/bash

sh ./docker_ce_build_ppc64/dockerd-entrypoint.sh &

source ./docker_ce_build_ppc64/dockerd-starting.sh
echo $DAEMON
echo $pid

if [ ! -z "$pid" ]
then
    if ! test -d /root/.docker 
    then
    mkdir /root/.docker
    echo "$SECRET_AUTH" > /root/.docker/config.json
    fi
    if grep -Fq "index.docker.io" /root/.docker/config.json
    then
        docker run hello-world
        kill -9 $pid && exit 0
    fi
fi