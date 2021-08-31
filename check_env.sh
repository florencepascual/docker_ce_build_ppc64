#!/bin/bash

echo $0

case $0 in
	env.list)
        # file which we edit with DOCKER_VERS, CONTAINERD_VERS and PACKAGING_REF
		echo "env.list"
        if ! grep -Fq "DOCKER_VERS" $0
        # if there is no docker_ce version
        then
            echo "There is no version of docker_ce"
            exit 1
        fi
        if ! grep -Fq "CONTAINERD_VERS" $0
        # if there is no containerd version
        then 
            echo "There is no version of containerd"
            exit 1
        fi
        if ! grep -Fq "PACKAGING_REF" $0
        # if there is no reference of docker-ce-packaging (hash commit) 
        then
            echo "There is no reference of docker-ce-packaging"
            exit 1
        fi
		;;
	env_distrib.list)
		echo "env_distrib.list"
		if ! grep -Fq "DEB_LIST" $0
        # if there is no deb_list
        then
            echo "There is no distro in DEB"
            exit 1
        fi
        if ! grep -Fq "RPM_LIST" $0
        # if there is no rpm_list
        then 
            echo "There is no distro in RPM"
            exit 1
        fi
		;;
	*)
		echo "There is no file with this name"
        exit 1
		;;
  esac



