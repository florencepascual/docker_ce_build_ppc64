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

mkdir -p ${PATH_COS}/s3_$COS_BUCKET
# mount the cos bucket
s3fs ${COS_BUCKET} ${PATH_COS}/s3_${COS_BUCKET} -o url=${URL_COS} -o passwd_file=${PATH_PASSWORD} -o ibm_iam_auth

# get the directory name
docker-ce-$DOCKER_CE_VER-$DOCKER_CE_BUILD_TAG
containerd-$CONTAINERD_VER-$CONTAINERD_BUILD_TAG


# copy the builds into the COS Bucket ibm-docker-builds
if [[ -d docker-ce-* ]]
then
    cp docker-ce-* ${PATH_COS}/s3_$COS_BUCKET
fi
if [[ -d containerd-* ]]
then
    cp containerd-* ${PATH_COS}/s3_$COS_BUCKET
fi

