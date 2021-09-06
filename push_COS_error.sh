#!/bin/bash

# if no error push to cos ibm-docker-builds and push to ppc64le-docker and delete the last version in ppc64le-docker
# if errors, push only to ppc64le-docker but don't delete last version

PATH_COS="/mnt"
PATH_PASSWORD="/root/.s3fs_cos_secret"

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

ls -d /workspace/docker-ce-*
if [[ $? -eq 0]]
    # copy the builds into the COS Bucket ppc64le-docker
    DIR_DOCKER_PRIVATE=docker-ce-${DOCKER_VERS}
    # copy the package to the cos bucket
    # cp -r /workspace/docker-ce-* ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/docker-ce/${DIR_DOCKER_PRIVATE}
    echo "${DIR_DOCKER_PRIVATE} copied"
fi

if [[ ${CONTAINERD_VERS} != "0" ]]
# if CONTAINERD_VERS contains a version of containerd
then
    ls -d /workspace/containerd-*
    if [[ $? -eq 0]]
        # copy the builds in the COS bucket ppc64le-docker
        DIR_CONTAINERD_PRIVATE=containerd-${CONTAINERD_VERS}
        # copy the package to the cos bucket
        # cp -r /workspace/containerd-* ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}/docker-ce/${DIR_CONTAINERD_PRIVATE}
        echo "${DIR_CONTAINERD_PRIVATE} copied"
    fi
fi

# check if pushed to both and exit 0