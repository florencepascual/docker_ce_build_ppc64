#!/bin/bash

# if no error push to cos ibm-docker-builds and push to ppc64le-docker and delete the last version in ppc64le-docker
# if errors, push only to ppc64le-docker but don't delete last version

# $1 -> ERR or NOERR

set -e

PATH_COS="/mnt"
PATH_PASSWORD="/root/.s3fs_cos_secret"

COS_BUCKET_SHARED="ibm-docker-builds"
URL_COS_SHARED="https://s3.us-east.cloud-object-storage.appdomain.cloud"

COS_BUCKET_PRIVATE="ppc64le-docker"
URL_COS_PRIVATE="https://s3.us-south.cloud-object-storage.appdomain.cloud"

echo ":" > ${PATH_PASSWORD}_buffer
echo "$SECRET_S3" >> ${PATH_PASSWORD}_buffer
tr -d '\n' < ${PATH_PASSWORD}_buffer > ${PATH_PASSWORD}
chmod 600 ${PATH_PASSWORD}
rm ${PATH_PASSWORD}_buffer
apt update && apt install -y s3fs

# ppc64le-docker

mkdir -p ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}
# mount the cos bucket
s3fs ${COS_BUCKET_PRIVATE} ${PATH_COS}/s3_${COS_BUCKET_PRIVATE} -o url=${URL_COS_PRIVATE} -o passwd_file=${PATH_PASSWORD} -o ibm_iam_auth

# if there are no errors
if [[ $1 -eq "NOERR" ]]
then
    # delete the last packages (both if CONTAINERD_VERS != 0)
    # remove last version of docker-ce and last tests
    # rm -rf ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/docker-ce-*
    # rm -rf ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/test-*
    echo "${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/docker-ce-* deleted"
    echo "${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/test-* deleted"

    if [[ ${CONTAINERD_VERS} != "0" ]]
    # if CONTAINERD_VERS contains a version of containerd
    then
        # remove last version of containerd and last tests
        # rm -rf ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/containerd-*
        echo "${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/containerd-* deleted"
    fi

    echo "ibm-docker-builds"
    # ibm-docker-builds

    mkdir -p ${PATH_COS}/s3_${COS_BUCKET_SHARED}
    # mount the cos bucket
    s3fs ${COS_BUCKET_SHARED} ${PATH_COS}/s3_${COS_BUCKET_SHARED} -o url=${URL_COS_SHARED} -o passwd_file=${PATH_PASSWORD} -o ibm_iam_auth
    ls ${PATH_COS}/s3_${COS_BUCKET_SHARED}

    ls -d ${PATH_COS}/s3_${COS_BUCKET_SHARED}/docker-ce-*/
    # copy the builds into the COS Bucket ibm-docker-builds
    if [[ $? -eq 0 ]]
    then
        # get the directory name "docker-ce-20.10-11" version without patch number then build tag
        # DIR_DOCKER_VERS=$(eval "echo ${DOCKER_VERS} | sed -E 's|(v)([0-9.]+)([0-9]+)(.[0-9])|\2\3|'")
        DIR_DOCKER_VERS=$(eval "echo ${DOCKER_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
        DOCKER_LAST_BUILD_TAG=$(ls -d ${PATH_COS}/s3_${COS_BUCKET_SHARED}/docker-ce-${DIR_DOCKER_VERS}-* | sort --version-sort | tail -1| cut -d'-' -f6)
        DOCKER_BUILD_TAG=$((DOCKER_LAST_BUILD_TAG+1))
        DIR_DOCKER_SHARED=docker-ce-${DIR_DOCKER_VERS}-${DOCKER_BUILD_TAG}
        # copy the package to the cos bucket
        # cp -r /workspace/docker-ce-* ${PATH_COS}/s3_${COS_BUCKET_SHARED}/${DIR_DOCKER_SHARED}
        echo "${DIR_DOCKER_SHARED} copied"
    else 
        # there are no directories yet
        DIR_DOCKER_VERS=$(eval "echo ${DOCKER_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
        DOCKER_BUILD_TAG="1"
        DIR_DOCKER_SHARED=docker-ce-${DIR_DOCKER_VERS}-${DOCKER_BUILD_TAG}
        # copy the package to the cos bucket
        # cp -r /workspace/docker-ce-* ${PATH_COS}/s3_${COS_BUCKET_SHARED}/${DIR_DOCKER_SHARED}
        echo "${DIR_DOCKER_SHARED} copied"
    fi
    if [[ ${CONTAINERD_VERS} != "0" ]]
    then
        ls -d ${PATH_COS}/s3_${COS_BUCKET_SHARED}/containerd-*/
        if [[ $? -eq 0 ]]
        then
            # get the directory name "containerd-1.4-9" version without patch number then build tag
            # DIR_CONTAINERD_VERS=$(eval "echo ${CONTAINERD_VERS} | sed -E 's|(v)([0-9.]+)([0-9]+)(.[0-9])|\2\3|'")
            DIR_CONTAINERD_VERS=$(eval "echo ${CONTAINERD_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
            CONTAINERD_LAST_BUILD_TAG=$(ls -d ${PATH_COS}/s3_${COS_BUCKET_SHARED}/containerd-${DIR_CONTAINERD_VERS}-* | sort --version-sort | tail -1| cut -d'-' -f5)
            CONTAINERD_BUILD_TAG=$((CONTAINERD_LAST_BUILD_TAG+1))
            DIR_CONTAINERD=containerd-${DIR_CONTAINERD_VERS}-${CONTAINERD_BUILD_TAG}
            # copy the package to the cos bucket
            # cp -r /workspace/containerd-* ${PATH_COS}/s3_${COS_BUCKET_SHARED}/${DIR_CONTAINERD}
            echo "${DIR_CONTAINERD} copied"
        else
            # there are no directories yet
            DIR_CONTAINERD_VERS=$(eval "echo ${CONTAINERD_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
            CONTAINERD_BUILD_TAG="1"
            DIR_CONTAINERD=docker-ce-${DIR_CONTAINERD_VERS}-${CONTAINERD_BUILD_TAG}
            # copy the package to the cos bucket
            # cp -r /workspace/containerd-* ${PATH_COS}/s3_${COS_BUCKET_SHARED}/${DIR_CONTAINERD}
            echo "${DIR_CONTAINERD} copied"
        fi
    fi
fi

# push packages, no matter what $1 is
ls -d /workspace/docker-ce-*
if [[ $? -eq 0]]
    # copy the builds into the COS Bucket ppc64le-docker and the tests
    DIR_DOCKER_PRIVATE=docker-ce-${DOCKER_VERS}
    # copy the package to the cos bucket
    # cp -r /workspace/docker-ce-* ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/${DIR_DOCKER_PRIVATE}
    # cp -r /workspace/test-* ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/
    echo "${DIR_DOCKER_PRIVATE} copied"
    echo "/workspace/test-* copied"
fi

if [[ ${CONTAINERD_VERS} != "0" ]]
# if CONTAINERD_VERS contains a version of containerd
then
    ls -d /workspace/containerd-*
    if [[ $? -eq 0]]
        # copy the builds in the COS bucket ppc64le-docker
        DIR_CONTAINERD_PRIVATE=containerd-${CONTAINERD_VERS}
        # copy the package to the cos bucket
        # cp -r /workspace/containerd-* ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/${DIR_CONTAINERD_PRIVATE}
        echo "${DIR_CONTAINERD_PRIVATE} copied"
    fi
fi

# check if pushed to COS Buckets and stop the container

if [[ test -d  ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/${DIR_DOCKER_PRIVATE} ]] && [[ test -d ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/test-* ]]
then
    echo "DOCKER_CE and TEST in the private COS bucket"
    if [[ ${CONTAINERD_VERS} != "0" ]] 
    then
        if [[ test -d ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/prow-docker/${DIR_CONTAINERD_PRIVATE} ]]
        then
            # packages pushed to the private cos bucket
            echo "CONTAINERD in the private COS bucket"
            BOOL_PRIVATE=1
        else
            # packages not pushed to the private cos bucket
            echo "CONTAINERD not in the private COS bucket"
            exit 1
        fi
    fi
else
    echo "DOCKER_CE and TEST not in the private COS bucket"
    exit 1 
fi

if [[ $1 -eq "NOERR" ]] && [[ BOOL_PRIVATE -eq 1 ]]
then
    if [[ test -d ${PATH_COS}/s3_${COS_BUCKET_SHARED}/${DIR_DOCKER_SHARED} ]]
    then
        echo "DOCKER_CE and TEST in the shared COS bucket"
        if [[ test -d ${PATH_COS}/s3_${COS_BUCKET_SHARED}/${DIR_CONTAINERD} ]]
            then
                # packages pushed to the shared cos bucket
                echo "CONTAINERD in the shared COS bucket"
                exit 0
            else
                # packages not pushed to the shared cos bucket
                echo "CONTAINERD not in the shared COS bucket"
                exit 1
        fi
    else 
        echo "DOCKER_CE and TEST not in the shared COS bucket"
        exit 0
    fi
fi