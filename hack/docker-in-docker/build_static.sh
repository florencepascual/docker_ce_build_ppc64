#!/bin/bash
# Script building the static docker packages
# in the directory docker-ce-v20.10.9 where there is a static directory with the script
# docker run -d -v /home/fpascual/docker-ce-v20.10.9:/workspace --privileged quay.io/powercloud/docker-ce-build -name docker-build-static 
# docker exec -it docker-build-static /bin/bash
# ./static/build_static.sh

set -ue

set -o allexport
source env.list
source env-distrib.list

DIR_DOCKER="/workspace/docker-ce-${DOCKER_VERS}"
if ! test -d ${DIR_DOCKER}
then
  mkdir ${DIR_DOCKER}
fi

#Workaround for builkit cache issue where fedora-32/Dockerfile
# (or the 1st Dockerfile used by buildkit) is used for all fedora's version
# See https://github.com/moby/buildkit/issues/1368
patchDockerFiles() {
  Dockfiles="$(find $1  -name 'Dockerfile')"
  d=$(date +%s)
  i=0
  for file in $Dockfiles; do
      i=$(( i + 1 ))
      echo "patching timestamp for $file"
      touch -d @$(( d + i )) "$file"
  done
}

echo "Populating docker-ce-packaging from git ref=$PACKAGING_REF"

PACKAGING_DIR="docker-ce-packaging"
mkdir $PACKAGING_DIR
pushd $PACKAGING_DIR

git init
git remote add origin  https://github.com/docker/docker-ce-packaging.git
git fetch --depth 1 origin $PACKAGING_REF
git checkout FETCH_HEAD


echo "populate docker-ce-packaging/src folders"
make REF=${DOCKER_VERS} checkout
popd

echo "building static"
pushd docker-ce-packaging/static
#patchDockerFiles .
VERSION=${DOCKER_VERS} CONTAINERD_VERSION=v1.4.11 RUNC_VERSION=v1.0.2 make static-linux
popd

cp docker-ce-packaging/static/build/linux/*.tgz ${DIR_DOCKER}

pushd ${DIR_DOCKER}
FILES="*"
for f in $FILES
do
  mv $f "${f//${DOCKER_VERS}/ppc64le}"
done
popd