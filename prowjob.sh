#!/bin/bash

# path to the github repository
PATH_GITHUB="https://github.com/florencepascual/docker_ce_build_ppc64.git"
DIR_GITHUB="docker_ce_build_ppc64"
# path to the image for building and testing
PATH_IMAGE_BUILD="quay.io/florencepascual"
# path to the scripts 
PATH_SCRIPTS="hack/docker-in-docker"
# path to test.sh, script to test docker-ce and containerd.
PATH_IMAGES="images/docker-in-docker"


git clone ${PATH_GITHUB}
wget -O ${DIR_GITHUB}/${PATH_SCRIPTS}/dockerd-entrypoint.sh https://raw.githubusercontent.com/docker-library/docker/master/dockerd-entrypoint.sh
chmod a+x ${DIR_GITHUB}/${PATH_SCRIPTS}/*.sh

# docker daemon to be enabled in the pod not for testing
# bash ${PATH_DOCKERD_ENTRYPOINT}/dockerd-entrypoint.sh &
# wait for the dockerd to start
source ./${DIR_GITHUB}/${PATH_SCRIPTS}/dockerd-starting.sh

mkdir /root/.docker
echo "${SECRET_AUTH}" > /root/.docker/config.json

# get env files or generate them


# get the env file and the dockertest repo and the latest built of containerd if we don't want to build containerd
CONT_NAME=docker_s3_env
docker run --env SECRET_S3 -d -v /workspace:/workspace --privileged --name $CONT_NAME debian:bullseye /bin/bash -c "/workspace/${DIR_GITHUB}/${PATH_SCRIPTS}/get_env.sh"
status_code="$(docker container wait $CONT_NAME)"
if [[ ${status_code} -ne 0 ]]
then
    exit
fi

set -o allexport
source env.list

# generate the env-distrib.list
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
# if we monitor github repo and put the versions into an env.list
#echo DOCKER_VERS=\"`git ls-remote --refs --tags https://github.com/moby/moby.git | cut --delimiter='/' --fields=3 | grep 'v20' | sort --version-sort | tail --lines=1`\" > env.list
#echo CONTAINERD_VERS=\"`git ls-remote --refs --tags https://github.com/containerd/containerd.git | cut --delimiter='/' --fields=3 | grep v1.4 | sort --version-sort | tail --lines=1`\" >> env.list
# check COS Bucket to see if DOCKER_VERS and CONTAINERD_VERS are new versions

# check the env.list (versions of docker-ce, containerd and list of packages)
if [[ -f env.list && -f env-distrib.list ]]
# if there is env.list and env-distrib.list
then
    set -o allexport
    source env.list
    source env-distrib.list
else
    echo "There is no env.list and/or env-distrib.list"
    exit 1
fi

# while the docker daemon is running
if [ ! -z "$pid" ]
then
    # container to build docker-ce and containerd
    CONT_NAME=docker-build
    docker pull ${PATH_IMAGE_BUILD}/docker_ce_build # à changer !!!!

    # docker exec -dt docker-build nohup bash -x "/workspace/${DIR_GITHUB}/build.sh"
    # https://nickjanetakis.com/blog/docker-tip-80-waiting-for-detached-containers-to-finish and stop the containers

    docker run --env DOCKER_VERS --env CONTAINERD_VERS --env PACKAGING_REF --env DEBS --env RPMS --env SECRET_AUTH --init -d -v /workspace:/workspace --privileged --name $CONT_NAME --entrypoint ./${DIR_GITHUB}/${PATH_SCRIPTS}/build.sh ${PATH_IMAGE_BUILD}/docker_ce_build

    status_code="$(docker container wait $CONT_NAME)"
    if [[ status_code -ne 0 ]]
    then
        # stop /
    fi

    # change CONTAINERD_VERS to the version of the last version built
    if [[ ${CONTAINERD_VERS} -eq 0 ]]
    then
        ls -d /workspace/containerd-*
        if [[ $? -ne 0 ]]
        then
            echo "There is no containerd package."
            exit 1
        fi
        CONTAINERD_VERS=$(eval "ls -d /workspace/containerd-* | cut -d'-' -f2")
    fi

    # container to test the packages
    CONT_NAME=docker-test
    docker run --env SECRET_AUTH --init -d -v /workspace:/workspace --privileged --name $CONT_NAME --entrypoint ./docker_ce_build_ppc64/test.sh ${PATH_IMAGE_BUILD}/docker_ce_build

    # check tests

    # push to cos bucket ibm-docker-builds and change ppc64le-docker if no error
    # if errors : push only to ppc64le-docker

fi
