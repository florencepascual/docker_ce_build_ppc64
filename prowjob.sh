#!/bin/bash

# path to the github repository
PATH_GITHUB="https://github.com/florencepascual/docker_ce_build_ppc64.git"
DIR_GITHUB="docker_ce_build_ppc64"
# path to the dockerd-entrypoint.sh
PATH_DOCKERD_ENTRYPOINT="/usr/local/bin"
# path to the dockerd-starting.sh
PATH_DOCKERD_STARTING=""
# path to the image for building and testing
PATH_IMAGE_BUILD="quay.io/florencepascual"
# path to test.sh, script to test docker-ce and containerd.
PATH_SCRIPT_TEST="/test"

# get env files or generate them
git clone ${PATH_GITHUB}
chmod +x ${DIR_GITHUB}/*.sh

#if $1
#then
#    env_source=$1
#    case $env_source in
#	"files")
        # env.list from COS Bucket and env-distrib.list 
CONT_NAME=docker_s3_env
docker run --rm --env SECRET_S3 -it -v /workspace:/workspace --privileged --name $CONT_NAME debian:bullseye /bin/bash -c "/workspace/${DIR_GITHUB}/get_COS_env.sh"
#		;;
#	"no-files")
#        # no files, we would monitor github repo and put the versions into an env.list
#        echo DOCKER_VERS=\"`git ls-remote --refs --tags https://github.com/moby/moby.git | cut --delimiter='/' --fields=3 | grep 'v20' | sort --version-sort | tail --lines=1`\" > env.list
#        echo CONTAINERD_VERS=\"`git ls-remote --refs --tags https://github.com/containerd/containerd.git | cut --delimiter='/' --fields=3 | grep v1.4 | sort --version-sort | tail --lines=1`\" >> env.list
#		# check COS Bucket to see if DOCKER_VERS and CONTAINERD_VERS are new versions
#       ;;
#	*)
#		echo "There is no argument valid"
#        exit 1
#		;;
#  esac

cat env.list

# check the env.list (versions of docker-ce, containerd and list of packages)
if [[ -f env.list ]]
# if there is env.list
then
    . .${PATH_CHECK_ENV}/check_env.sh env.list
    cat env.list
    set -o allexport
    source env.list
else
    echo "There is no env.list"
    exit 1
fi

# docker daemon to be enabled in the pod not for testing
# bash ${PATH_DOCKERD_ENTRYPOINT}/dockerd-entrypoint.sh &
# wait for the dockerd to start
. .${PATH_DOCKERD_STARTING}/dockerd-starting.sh
# while the docker daemon is running
if [ ! -z "$pid" ]
then
    # get the list of distros
    . ./${DIR_GITHUB}/get_distrib.sh
    if [[ -f env-distrib.list ]]
    then
        . .${PATH_CHECK_ENV}/check_env.sh env-distrib.list
        cat env-distrib.list
        set -o allexport
        source env-distrib.list
    else
        echo "There is no env-distrib.list"
        exit 1
    fi

    
docker run --rm --env SECRET_S3 -it -v /workspace:/workspace --privileged --name $CONT_NAME debian:bullseye /bin/bash -c "/workspace/${DIR_GITHUB}/get_COS_env.sh"
    # container to build docker-ce and containerd
    CONT_NAME=docker-build
    docker pull ${PATH_IMAGE_BUILD}/docker_ce_build
    docker run --env-file /workspace/env.list --env-file /workspace/env-distrib.list -it -v /workspace:/workspace --privileged --name $CONT_NAME docker_ce_build /bin/bash -c "$/workspace/${DIR_GITHUB}/build.sh"

    # store the new versions in the cos bucket ppc64le (or in the container ?)

    # container to test docker-ce and containerd
    #CONT_NAME=docker-test
    # !!!! PRENDRE EN COMPTE SECRET
    #docker run -d -v /home/aurelien/docker-ce:/docker-ce -v  /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME docker_ce_build .${PATH_SCRIPT_TEST}/test.sh
    # check tests

    # push to cos bucket ibm-docker-builds and change ppc64le-docker if no error
    # if errors : push only to ppc64le-docker

fi
