#!/bin/bash

# https://nickjanetakis.com/blog/docker-tip-80-waiting-for-detached-containers-to-finish and stop the containers


# path to the github repository
PATH_GITHUB="https://github.com/florencepascual/docker_ce_build_ppc64.git"
DIR_GITHUB="docker_ce_build_ppc64"
# path to the image for building and testing
PATH_IMAGE_BUILD="quay.io/florencepascual"
# path to the scripts 
PATH_SCRIPTS="/workspace/docker_ce_build_ppc64/hack/docker-in-docker"
# path to the images for the tests
PATH_IMAGES="/workspace/docker_ce_build_ppc64/images/docker-in-docker"

# clone the directory where the scripts are
echo "* Git clone *"
git clone ${PATH_GITHUB}
if ! test -d ${DIR_GITHUB}
then
echo "The directory from ${PATH_GITHUB} was not cloned. "
exit 1
fi
wget -O ${PATH_SCRIPTS}/dockerd-entrypoint.sh https://raw.githubusercontent.com/docker-library/docker/master/dockerd-entrypoint.sh
if ! test -f ${PATH_SCRIPTS}/dockerd-entrypoint.sh
then
echo "The dockerd-entrypoint file was not downloaded. "
exit 1
fi
chmod a+x ${PATH_SCRIPTS}/*.sh

# start the dockerd
echo "** Dockerd **"
bash ${PATH_SCRIPTS}/dockerd-entrypoint.sh &
source ${PATH_SCRIPTS}/dockerd-starting.sh

if [ ! -z "$pid" ]
then
    if ! test -d /root/.docker 
    then
        # docker login
        echo "*** Docker login ***"
        mkdir /root/.docker
        echo "$SECRET_AUTH" > /root/.docker/config.json
    fi
    if grep -Fq "index.docker.io" /root/.docker/config.json
    then
        # get the env file and the dockertest repo and the latest built of containerd if we don't want to build containerd
        echo "*** * COS Bucket * ***"
        CONT_NAME=docker_s3_env
        docker run --env SECRET_S3 -d -v /workspace:/workspace --privileged --name $CONT_NAME debian:bullseye /bin/bash -c "${PATH_SCRIPTS}/get_env.sh"
        status_code="$(docker container wait $CONT_NAME)"
        echo $status_code

        if [[ ${status_code} -ne 0 ]]
        then
        echo "The docker to get the env.list and the dockertest has failed."
            exit 1
        fi
        ls
        if [[ -f env.list ]]
        then
        # check there are 3 env variables in env.list
        if grep -Fq "DOCKER_VERS" env.list && grep -Fq "CONTAINERD_VERS" env.list && grep -Fq "PACKAGING_REF" env.list
        then 
            echo "DOCKER_VERS, CONTAINERD_VERS, PACKAGING_REF are in env.list"
        else 
            echo "DOCKER_VERS, CONTAINERD_VERS and/or PACKAGING_REF are not in env.list"
            exit 1
        fi
        set -o allexport
        source env.list
        echo "DEBUG ENV.LIST"
        echo $DOCKER_VERS
        echo $CONTAINERD_VERS
        echo $PACKAGING_REF
        else
        echo "There is no env.list"
        fi
        
        # generate the env-distrib.list
        echo "*** ** env-distrib.list ** ***"
        mkdir docker-ce-packaging
        pushd docker-ce-packaging
        git init
        git remote add origin  https://github.com/docker/docker-ce-packaging.git
        git fetch --depth 1 origin ${PACKAGING_REF}
        git checkout FETCH_HEAD

        make REF=${DOCKER_VERS} checkout
        popd

        # get the packages list in the env_distrib.list
        echo DEBS=\"`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*`\" > env-distrib.list
        echo RPMS=\"`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*`\" >> env-distrib.list

        rm -rf docker-ce-packaging

        # CHANGE ENV-DISTRIB.LIST HERE
        rm env-distrib.list
        echo DEBS=\"debian-bullseye\" > env-distrib.list
        echo RPMS=\"fedora-33\" >> env-distrib.list

        # check the env.list (versions of docker-ce, containerd and list of packages)
        if [[ -f env-distrib.list ]]
        # if there is env.list and env-distrib.list
        then
        # check if there are two variables in env-distrib.list
        if grep -Fq "DEBS" env-distrib.list && grep -Fq "RPMS" env-distrib.list
        then 
            echo "DEBS and RPMS are in env-distrib.list"
        else 
            echo "DEBS and/or RPMS are not in env-distrib.list"
            exit 1
        fi
        source env-distrib.list
        echo "DEBUG ENV-DISTRIB.LIST"
        echo $DEBS
        echo $RPMS
        else
        echo "There is no env-distrib.list"
        exit 1
        fi

        # build docker_ce and containerd
        echo "*** *** BUILD *** ***"
        CONT_NAME=docker-build
        docker run --env SECRET_AUTH --env PATH_SCRIPTS --init -d -v /workspace:/workspace --privileged --name $CONT_NAME --entrypoint .${PATH_SCRIPTS}/build.sh ${PATH_IMAGE_BUILD}/docker_ce_build
        docker logs --follow $CONT_NAME
        status_code="$(docker container wait $CONT_NAME)"
        if [[ ${status_code} -ne 0 ]]
        then
        echo "The docker supposed to build the packages has failed."
        exit 1
        fi

        # change the containerd environment variable
        if [[ ${CONTAINERD_VERS} -eq 0 ]]
        then
        ls -d /workspace/containerd-*
        if [[ $? -ne 0 ]]
        then
            echo "There is no containerd package."
            exit 1
        fi
        CONTAINERD_VERS=$(eval "ls -d /workspace/containerd-* | cut -d'-' -f2")
        echo ${CONTAINER_VERS}
        sed -i 's/CONTAINERD_VERS=0/CONTAINERD_VERS='${CONTAINERD_VERS}'/g' env.list
        cat env.list
        ls /workspace
        fi

        # test the packages
        echo "*** *** * TEST * *** ***"
        CONT_NAME=docker-test
        docker run --env SECRET_AUTH --env PATH_SCRIPTS--init -d -v /workspace:/workspace --privileged --name $CONT_NAME --entrypoint ${PATH_SCRIPTS}/test.sh ${PATH_IMAGE_BUILD}/docker_ce_build

        docker run --env SECRET_AUTH --init -d -v /workspace:/workspace --privileged --name $CONT_NAME ${PATH_IMAGE_BUILD}/docker_ce_build

        # check errors 

        # push to the COS Bucket

        # notifications

    fi
fi