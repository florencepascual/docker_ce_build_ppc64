#/bin/bash

if [[ ! -d docker-ce-packaging ]]
then
    echo "no docker-ce-packaging"
    git clone https://github.com/docker/docker-ce-packaging --depth 1
fi

if [[ ! -f env.list ]]
then
    echo "no env.list"
    touch env.list
fi
echo DEB_LIST=`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*` >> env.list
echo RPM_LIST=`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*` >> env.list

for PACKTYPE in RPM_LIST; do
  echo "There is $PACKTYPE"

  for DISTRO in ${!PACKTYPE}; do

    echo "There is $DISTRO"
  done
done