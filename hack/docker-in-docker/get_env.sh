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
cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/dockertest /workspace/test/src/github.ibm.com/powercloud/dockertest

# copy the latest built of containerd if CONTAINERD_VERS = "0"
set -o allexport
source /workspace/${FILE_ENV}

if [[ ${CONTAINERD_VERS} = "0" ]]
then
    cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/containerd-* /workspace/
fi



# ## check the env.list file

# grep -FLq "DOCKER_VERS" ${FILE_ENV}
# if [[ $? -eq 1 ]]
# # if there is no docker_ce version
# then
#     echo "There is no version of docker_ce"
#     exit 1
# fi
# grep -FLq "CONTAINERD_VERS" ${FILE_ENV}
# if [[ $? -eq 1 ]]
# # if there is no containerd version
# then 
#     echo "There is no version of containerd"
#     exit 1
# fi
# grep -FLq "PACKAGING_REF" ${FILE_ENV}
# if [[ $? -eq 1 ]]
# # if there is no reference of docker-ce-packaging (hash commit) 
# then
#     echo "There is no reference of docker-ce-packaging"
#     exit 1
# fi

# ## check the env-distrib.list

# grep -FLq "DEBS" ${FILE_ENV_DISTRIB}
# if [[ $? -eq 1 ]]
# # if there is no DEBS
# then
#     echo "There is no distro in DEB"
#     exit 1
# fi
# grep -FLq "RPMS" ${FILE_ENV_DISTRIB}
# if [[ $? -eq 1 ]]
# # if there is no RPMS
# then 
#     echo "There is no distro in RPM"
#     exit 1
# fi
