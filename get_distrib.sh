#!/bin/bash

if [[ -d docker-ce-packaging ]]
# if there is no docker-ce-packaging, git clone with depth 1
then
    rm -rf docker-ce-packaging
fi
mkdir docker-ce-packaging
pushd docker-ce-packaging
git init
git remote add origin  https://github.com/docker/docker-ce-packaging.git
git fetch --depth 1 origin $PACKAGING_REF
git checkout FETCH_HEAD

make REF=$DOCKER_VERS checkout
popd

if [[ ! -f env-distrib.list ]]
# if there is no env.list file, create the file
then
    touch env-distrib.list
else
# if there is already DEB_LIST or RPM_LIST, remove these lines
    if grep -Fq "DEB_LIST" env-distrib.list
    then
        sed -i '/^DEB_LIST/d' env-distrib.list
    fi
    if grep -Fq "RPM_LIST" env-distrib.list
    then 
        sed -i '/^RPM_LIST/d' env-distrib.list
    fi
fi

# get the packages list in the env_distrib.list
echo DEB_LIST=\"`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*`\" >> env-distrib.list
echo RPM_LIST=\"`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*`\" >> env-distrib.list
