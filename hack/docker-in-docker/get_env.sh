#!/bin/bash

## get the env.list file and the dockertest from the ppc64le-docker COS bucket

PATH_COS="/mnt"
PATH_PASSWORD="/root/.s3fs_cos_secret"

COS_BUCKET="ppc64le-docker"
URL_COS="https://s3.us-south.cloud-object-storage.appdomain.cloud"
FILE_ENV="env.list"
FILE_ENV_DISTRIB="env-distrib.list"

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
cp ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/${FILE_ENV} /workspace/${FILE_ENV}

# copy the dockertest repo to the local /workspace
mkdir -p /workspace/test/src/github.ibm.com/powercloud/
cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/dockertest /workspace/test/src/github.ibm.com/powercloud/dockertest

# copy the latest built of containerd if CONTAINERD_VERS = "0"
set -o allexport
source /workspace/${FILE_ENV}

rm /workspace/${FILE_ENV}
echo DOCKER_VERS="v20.10.8" > /workspace/${FILE_ENV}
echo CONTAINERD_VERS="0" >> /workspace/${FILE_ENV}
echo PACKAGING_REF="5a28c77f52148f682ab1165dfcbbbad6537b148f" >> /workspace/${FILE_ENV}

if [[ ${CONTAINERD_VERS} = "0" ]]
then
    cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/containerd-* /workspace/
fi

# check we have the env.list, the dockertest and the containerd packages if CONTAINERD_VERS = 0
if test -f /workspace/${FILE_ENV} && test -d /workspace/test/src/github.ibm.com/powercloud/dockertest
then
    if [[ ${CONTAINERD_VERS} = "0" ]]
    then
        if test -d /workspace/containerd-*
        then
            echo "The containerd packages have been copied."
            exit 0
        else
            echo "The containerd packages have not been copied."
            exit 1
        fi
    else
        echo "The env.list and the dockertest directory have been copied."
        exit 0
    fi
else 
    echo "The env.list and/or the dockertest directory have not been copied."
    exit 1
fi