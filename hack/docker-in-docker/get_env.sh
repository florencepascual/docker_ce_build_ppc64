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
cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/dockertest /workspace/dockertest

# copy the latest built of containerd if CONTAINERD_VERS = "0"
set -o allexport
source ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/${FILE_ENV}

if [[ ${CONTAINERD_VERS} = "0" ]]
then
    cp -r ${PATH_COS}/s3_${COS_BUCKET}/prow-docker/containerd-* /workspace/
fi



## generate the env-distrib.list file

if [[ -d docker-ce-packaging ]]
# if there is no docker-ce-packaging, git clone with depth 1
then
    rm -rf docker-ce-packaging
fi
mkdir docker-ce-packaging
pushd docker-ce-packaging
git init
git remote add origin  https://github.com/docker/docker-ce-packaging.git
git fetch --depth 1 origin ${PACKAGING_REF}
git checkout FETCH_HEAD

make REF=${DOCKER_VERS} checkout
popd

if [[ ! -f ${FILE_ENV_DISTRIB} ]]
# if there is no env.list file, create the file
then
    touch ${FILE_ENV_DISTRIB}
else
# if there is already DEBS or RPMS, remove these lines
    if grep -Fq "DEBS" ${FILE_ENV_DISTRIB}
    then
        sed -i '/^DEBS/d' ${FILE_ENV_DISTRIB}
    fi
    if grep -Fq "RPMS" ${FILE_ENV_DISTRIB}
    then 
        sed -i '/^RPMS/d' ${FILE_ENV_DISTRIB}
    fi
fi

# get the packages list in the env_distrib.list
echo DEBS=\"`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*`\" >> ${FILE_ENV_DISTRIB}
echo RPMS=\"`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*`\" >> ${FILE_ENV_DISTRIB}

rm -rf docker-ce-packaging


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
