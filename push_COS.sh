#!/bin/bash

# if no error push to cos ibm-docker-builds and push to ppc64le-docker
# if errors, push only to ppc64le-docker

PATH_COS="/mnt"
PATH_PASSWORD="/root/.s3fs_cos_secret"

COS_BUCKET="ibm-docker-builds"
URL_COS="https://s3.us-east.cloud-object-storage.appdomain.cloud"

echo ":" > ${PATH_PASSWORD}_buffer
echo "$SECRET_S3" >> ${PATH_PASSWORD}_buffer
tr -d '\n' < ${PATH_PASSWORD}_buffer > ${PATH_PASSWORD}
chmod 600 ${PATH_PASSWORD}
rm ${PATH_PASSWORD}_buffer
apt update && apt install -y s3fs

mkdir -p ${PATH_COS}/s3_${COS_BUCKET}
# mount the cos bucket
s3fs ${COS_BUCKET} ${PATH_COS}/s3_${COS_BUCKET} -o url=${URL_COS} -o passwd_file=${PATH_PASSWORD} -o ibm_iam_auth

ls -d ${PATH_COS}/s3_${COS_BUCKET}/docker-ce-*/
# copy the builds into the COS Bucket ibm-docker-builds
if [[ $? -eq 0 ]]
then
    # get the directory name "docker-ce-20.10-11" version without patch number then build tag
    # DIR_DOCKER_VERS=$(eval "echo ${DOCKER_VERS} | sed -E 's|(v)([0-9.]+)([0-9]+)(.[0-9])|\2\3|'")
    DIR_DOCKER_VERS=$(eval "echo ${DOCKER_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
    DOCKER_LAST_BUILD_TAG=$(ls -d ${PATH_COS}/s3_${COS_BUCKET}/docker-ce-${DIR_DOCKER_VERS}-* | sort --version-sort | tail -1| cut -d'-' -f6)
    DOCKER_BUILD_TAG=$((DOCKER_LAST_BUILD_TAG+1))
    DIR_DOCKER=docker-ce-${DIR_DOCKER_VERS}-${DOCKER_BUILD_TAG}
    # copy the package to the cos bucket
    # cp /workspace/docker-ce-* ${PATH_COS}/s3_${COS_BUCKET}/${DIR_DOCKER}
    echo "${DIR_DOCKER} copied"
else 
    DIR_DOCKER_VERS=$(eval "echo ${DOCKER_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
    DOCKER_BUILD_TAG="1"
    DIR_DOCKER=docker-ce-${DIR_DOCKER_VERS}-${DOCKER_BUILD_TAG}
    # copy the package to the cos bucket
    # cp /workspace/docker-ce-* ${PATH_COS}/s3_${COS_BUCKET}/${DIR_DOCKER}
    echo "${DIR_DOCKER} copied"
fi
ls -d ${PATH_COS}/s3_${COS_BUCKET}/containerd-*/
if [[ $? -eq 0 ]]
then
    # get the directory name "containerd-1.4-9" version without patch number then build tag
    # DIR_CONTAINERD_VERS=$(eval "echo ${CONTAINERD_VERS} | sed -E 's|(v)([0-9.]+)([0-9]+)(.[0-9])|\2\3|'")
    DIR_CONTAINERD_VERS=$(eval "echo ${CONTAINERD_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
    CONTAINERD_LAST_BUILD_TAG=$(ls -d ${PATH_COS}/s3_${COS_BUCKET}/containerd-${DIR_CONTAINERD_VERS}-* | sort --version-sort | tail -1| cut -d'-' -f5)
    CONTAINERD_BUILD_TAG=$((CONTAINERD_LAST_BUILD_TAG+1))
    DIR_CONTAINERD=containerd-${DIR_CONTAINERD_VERS}-${CONTAINERD_BUILD_TAG}
    # copy the package to the cos bucket
    # cp /workspace/containerd-* ${PATH_COS}/s3_${COS_BUCKET}/${DIR_CONTAINERD}
    echo "${DIR_CONTAINERD} copied"
else
    DIR_CONTAINERD_VERS=$(eval "echo ${CONTAINERD_VERS} | cut -d'v' -f2 | cut -d'.' -f1-2")
    CONTAINERD_BUILD_TAG="1"
    DIR_CONTAINERD=docker-ce-${DIR_CONTAINERD_VERS}-${CONTAINERD_BUILD_TAG}
    # copy the package to the cos bucket
    # cp /workspace/containerd-* ${PATH_COS}/s3_${COS_BUCKET}/${DIR_CONTAINERD}
    echo "${DIR_CONTAINERD} copied"
fi

