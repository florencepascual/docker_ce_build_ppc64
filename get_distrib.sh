#!/bin/bash

if [[ ! -d docker-ce-packaging ]]
# if there is no docker-ce-packaging, git clone with depth 1
then
    git clone https://github.com/docker/docker-ce-packaging --depth 1
else
# if there is, update any changes
    cd docker-ce-packaging && git pull --depth 1 && cd ..
fi

if [[ ! -f env_distrib.list ]]
# if there is no env.list file, create the file
then
    touch env_distrib.list
else
# if there is already DEB_LIST or RPM_LIST, remove these lines
    if grep -Fq "DEB_LIST" env_distrib.list
    then
        sed -i '/^DEB_LIST/d' env_distrib.list
    fi
    if grep -Fq "RPM_LIST" env_distrib.list
    then 
        sed -i '/^RPM_LIST/d' env_distrib.list
    fi
fi

# get the packages list in the env_distrib.list
echo DEB_LIST=\"`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*`\" >> env_distrib.list
echo RPM_LIST=\"`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*`\" >> env_distrib.list
