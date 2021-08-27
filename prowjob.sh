#!/bin/bash

PATH_DOCKERD_ENTRYPOINT="/usr/local/bin"
PATH_DOCKERD_STARTING=""
PATH_IMAGE_BUILD="quay.io/florencepascual"
PATH_SCRIPT_BUILD=""
PATH_SCRIPT_TEST="/test"

# check if new versions of docker-ce and containerd
echo DOCKER_VERS=\"`git ls-remote --refs --tags https://github.com/moby/moby.git | cut --delimiter='/' --fields=3 | grep 'v20' | sort --version-sort | tail --lines=1`\" > env.list
echo CONTAINERD_VERS=\"`git ls-remote --refs --tags https://github.com/containerd/containerd.git | cut --delimiter='/' --fields=3 | grep v1.4 | sort --version-sort | tail --lines=1`\" >> env.list

# docker daemon
.${PATH_DOCKERD_ENTRYPOINT}/dockerd-entrypoint.sh &
# wait for the dockerd to start
. .${PATH_DOCKERD_STARTING}/dockerd-starting.sh
# while the docker daemon is running
if [ ! -z "$pid" ]
then
    # get the list of distros
    ./get_distrib.sh
    # check the env.list (versions of docker-ce, containerd and list of packages)
    if [[ ! -f env.list ]]
    # if there is no env.list
    then
        echo "There is no env.list"
        exit 1
    fi
    if grep -Fq "DOCKER_CE_VERS" env.list
    # if there is no docker_ce version
    then
        echo "There is no version of docker_ce"
        exit 1
    fi
    if grep -Fq "CONTAINERD_VERS" env.list
    # if there is no containerd version
    then 
        echo "There is no version of containerd"
        exit 1
    fi
    if grep -Fq "DEB_LIST" env.list
    # if there is no deb_list
    then
        echo "There is no distro in DEB"
        exit 1
    fi
    if grep -Fq "RPM_LIST" env.list
    # if there is no rpm_list
    then 
        echo "There is no distro in RPM"
        exit 1
    fi

    cat env.list
    # container to build docker-ce and containerd
    #CONT_NAME=docker-build
    #docker pull ${PATH_IMAGE_BUILD}/docker_ce_build
    # !!!! PRENDRE EN COMPTE SECRET
    #docker run -d -v /home/aurelien/docker-ce:/docker-ce -v /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME --env.file docker_ce_build .${PATH_SCRIPT_BUILD}/build.sh

    # store the new versions in the cos bucket ppc64le (or in the container ?)

    # container to test docker-ce and containerd
    #CONT_NAME=docker-test
    # !!!! PRENDRE EN COMPTE SECRET
    #docker run -d -v /home/aurelien/docker-ce:/docker-ce -v  /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME docker_ce_build .${PATH_SCRIPT_TEST}/test.sh
    # check tests

    # push to cos bucket ibm-docker-builds
fi
