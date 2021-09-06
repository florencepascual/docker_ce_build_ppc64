#!/bin/bash

# path to the github repository
PATH_GITHUB="https://github.com/florencepascual/docker_ce_build_ppc64.git"
DIR_GITHUB="docker_ce_build_ppc64"
# path to the dockerd-entrypoint.sh
PATH_DOCKERD_ENTRYPOINT="/usr/local/bin"
# path to the image for building and testing
PATH_IMAGE_BUILD="quay.io/florencepascual"
# path to test.sh, script to test docker-ce and containerd.
PATH_SCRIPT_TEST="/test"

git clone ${PATH_GITHUB}
chmod a+x ${DIR_GITHUB}/*.sh

# docker daemon to be enabled in the pod not for testing
# bash ${PATH_DOCKERD_ENTRYPOINT}/dockerd-entrypoint.sh &
# wait for the dockerd to start
source ./${DIR_GITHUB}/dockerd-starting.sh

mkdir /root/.docker
echo "${SECRET_AUTH}" > /root/.docker/config.json

# get env files or generate them


# get the env file and the dockertest repo and the latest built of containerd if we don't want to build containerd
CONT_NAME=docker_s3_env
docker run --env SECRET_S3 -it -v /workspace:/workspace --privileged --name $CONT_NAME debian:bullseye /bin/bash -c "/workspace/${DIR_GITHUB}/get_COS.sh"
status_code="$(docker container wait $CONT_NAME)"
if [[ status_code -ne 0 ]]
then
    # stop /
fi
# if we monitor github repo and put the versions into an env.list
#echo DOCKER_VERS=\"`git ls-remote --refs --tags https://github.com/moby/moby.git | cut --delimiter='/' --fields=3 | grep 'v20' | sort --version-sort | tail --lines=1`\" > env.list
#echo CONTAINERD_VERS=\"`git ls-remote --refs --tags https://github.com/containerd/containerd.git | cut --delimiter='/' --fields=3 | grep v1.4 | sort --version-sort | tail --lines=1`\" >> env.list
# check COS Bucket to see if DOCKER_VERS and CONTAINERD_VERS are new versions

cat env.list

# check the env.list (versions of docker-ce, containerd and list of packages)
if [[ -f env.list ]]
# if there is env.list
then
    source ./${DIR_GITHUB}/check_env.sh env.list
    cat env.list
    set -o allexport
    source env.list
else
    echo "There is no env.list"
    exit 1
fi


# while the docker daemon is running
if [ ! -z "$pid" ]
then
    # get the list of distros
    source ./${DIR_GITHUB}/get_distrib.sh
    if [[ -f env-distrib.list ]]
    then
        source ./${DIR_GITHUB}/check_env.sh env-distrib.list
        cat env-distrib.list
        set -o allexport
        source env-distrib.list
    else
        echo "There is no env-distrib.list"
        exit 1
    fi

    # container to build docker-ce and containerd
    CONT_NAME=docker-build
    docker pull ${PATH_IMAGE_BUILD}/docker_ce_build

    docker run --env DOCKER_VERS --env CONTAINERD_VERS --env PACKAGING_REF --env DEBS --env RPMS --env SECRET_AUTH -d -v /workspace:/workspace --privileged --name $CONT_NAME ${PATH_IMAGE_BUILD}/docker_ce_build
    docker exec -dt docker-build bash -c "/workspace/${DIR_GITHUB}/build.sh"
    # docker exec -dt docker-build nohup bash -x "/workspace/${DIR_GITHUB}/build.sh"
    # https://nickjanetakis.com/blog/docker-tip-80-waiting-for-detached-containers-to-finish and stop the containers
    status_code="$(docker container wait $CONT_NAME)"
    if [[ status_code -ne 0 ]]
    then
        # stop /
    fi
    # container to test the packages
    CONT_NAME=docker-test
    docker run -d -v /workspace:/workspace --privileged --name ${CONT_NAME} ${PATH_IMAGE_BUILD}/docker_ce_build
    docker exec -dt ${CONT_NAME} bash -c "/workspace/${DIR_GITHUB}/test/test_distrib.sh"

    docker run -d -v /home/aurelien/docker-ce:/docker-ce -v  /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME docker_ce_build .${PATH_SCRIPT_TEST}/test.sh
    # check tests

    # push to cos bucket ibm-docker-builds and change ppc64le-docker if no error
    # if errors : push only to ppc64le-docker

fi
