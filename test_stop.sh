#!/bin/bash

stop_docker_daemon() {
  ps -e | grep $1 # dockerd $DAEMON
  kill -9 $2 # pid $pid
}

source ./docker_ce_build_ppc64/dockerd-starting.sh
echo $DAEMON
echo $pid
if ! test -d /root/.docker 
then
  mkdir /root/.docker
  echo "$SECRET_AUTH" > /root/.docker/config.json
fi
if grep -Fq "index.docker.io" /root/.docker/config.json
then
    docker run hello-world
    exit 0
    stop_docker_daemon $DAEMON $pid
fi