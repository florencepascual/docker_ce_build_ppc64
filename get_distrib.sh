#/bin/bash

git clone https://github.com/docker/docker-ce-packaging --depth 1

DEB_LIST=`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*`
RPM_LIST=`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*`

echo $DEB_LIST
echo $RPM_LIST
