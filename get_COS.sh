#!/bin/bash

# get the env.list file from the ppc64le-docker COS bucket

PATH_COS="/mnt"
PATH_PASSWORD="/root/.s3fs_cos_secret"

COS_BUCKET="ppc64le-docker"
URL_COS="https://s3.us-south.cloud-object-storage.appdomain.cloud"

echo ":" > ${PATH_PASSWORD}_buffer
echo "$SECRET_S3" >> ${PATH_PASSWORD}_buffer
tr -d '\n' < ${PATH_PASSWORD}_buffer > ${PATH_PASSWORD}
chmod 600 ${PATH_PASSWORD}
rm ${PATH_PASSWORD}_buffer
apt update && apt install -y s3fs

mkdir -p ${PATH_COS}/s3_$COS_BUCKET
# mount the cos bucket
s3fs ${COS_BUCKET} ${PATH_COS}/s3_${COS_BUCKET} -o url=${URL_COS} -o passwd_file=${PATH_PASSWORD} -o ibm_iam_auth

# copy the env.list to the local /workspace
cp ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/env.list /workspace/env.list

# copy the dockertest repo to the local /workspace
cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/dockertest /workspace/dockertest

# copy the latest built of containerd if CONTAINERD_VERS = "0"
set -o allexport
source ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/env.list

if [[ ${CONTAINERD_VERS} = "0" ]]
then
    cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/containerd-* /workspace/
fi