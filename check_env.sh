#!/bin/bash

if ! grep -Fq "DOCKER_VERS" env.list
# if there is no docker_ce version
then
    echo "There is no version of docker_ce"
    exit 1
fi
if ! grep -Fq "CONTAINERD_VERS" env.list
# if there is no containerd version
then 
    echo "There is no version of containerd"
    exit 1
fi
if ! grep -Fq "PACKAGING_REF" env.list
# if there is no reference of docker-ce-packaging (hash commit) 
then
    echo "There is no reference of docker-ce-packaging"
    exit 1
fi
if ! grep -Fq "DEB_LIST" env.list
# if there is no deb_list
then
    echo "There is no distro in DEB"
    exit 1
fi
if ! grep -Fq "RPM_LIST" env.list
# if there is no rpm_list
then 
    echo "There is no distro in RPM"
    exit 1
fi
