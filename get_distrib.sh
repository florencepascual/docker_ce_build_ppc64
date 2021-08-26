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


#echo DEB_LIST=`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*` >> env.list
#echo RPM_LIST=`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*` >> env.list

DEB_LIST=debian-bullseye debian-buster ubuntu-bionic ubuntu-focal ubuntu-groovy ubuntu-hirsute
RPM_LIST=centos-7 centos-8 fedora-33 fedora-34

for PACKTYPE in RPM_LIST; do
  echo "There is $PACKTYPE"

  for DISTRO in ${!PACKTYPE}; do

    echo "There is $DISTRO"
  done
done