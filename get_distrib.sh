#/bin/bash

git clone https://github.com/docker/docker-ce-packaging --depth 1

echo DEB_LIST=`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*` >> env.list
echo RPM_LIST=`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*` >> env.list
