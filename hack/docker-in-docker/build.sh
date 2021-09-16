#!/bin/bash

set -e

sh ${PATH_SCRIPTS}/dockerd-entrypoint.sh &
source ${PATH_SCRIPTS}/dockerd-starting.sh

set -o allexport
source env.list
source env-distrib.list

if [ ! -z "$pid" ]
  then
    if ! test -d /root/.docker 
    then
      mkdir /root/.docker
      echo "$SECRET_AUTH" > /root/.docker/config.json
    fi
    if grep -Fq "index.docker.io" /root/.docker/config.json
    then
    # docker login
    echo ""
    echo "================================================="
    echo "==   Building docker-ce                         =="
    echo "================================================="

    DIR_DOCKER="/workspace/docker-ce-${DOCKER_VERS}"
    mkdir ${DIR_DOCKER}

    #Workaround for builkit cache issue where fedora-32/Dockerfile
    # (or the 1st Dockerfile used by buildkit) is used for all fedora's version
    # See https://github.com/moby/buildkit/issues/1368
    patchDockerFiles() {
      Dockfiles="$(find $1  -name 'Dockerfile')"
      d=$(date +%s)
      i=0
      for file in ${Dockfiles}; do
          i=$(( i + 1 ))
          echo "patching timestamp for ${file}"
          touch -d @$(( d + i )) "${file}"
      done
    }

    DIR_PACKAGING="docker-ce-packaging"

    mkdir -p ${DIR_PACKAGING}
    pushd ${DIR_PACKAGING}

    git init
    git remote add origin  https://github.com/docker/docker-ce-packaging.git
    git fetch --depth 1 origin ${PACKAGING_REF}
    git checkout FETCH_HEAD

    make REF=${DOCKER_VERS} checkout
    popd

    pushd docker-ce-packaging/deb
    patchDockerFiles .
    for DEB in ${DEBS}
    do
      echo ""
      echo "================================================="
      echo "==   Building for:${DEB}                         =="
      echo "================================================="

      VERSION=${DOCKER_VERS} make debbuild/bundles-ce-${DEB}-ppc64le.tar.gz
    done
    popd

    pushd docker-ce-packaging/rpm
    patchDockerFiles .
    for RPM in ${RPMS}
    do
      echo ""
      echo "================================================="
      echo "==   Building for:${RPM}                         =="
      echo "================================================="

      VERSION=${DOCKER_VERS} make rpmbuild/bundles-ce-${RPM}-ppc64le.tar.gz
    done
    popd

    echo ""
    echo "================================================="
    echo "==   Copying packages to ${DIR_DOCKER}        =="
    echo "================================================="

    cp -r docker-ce-packaging/deb/debbuild/* ${DIR_DOCKER}
    cp -r docker-ce-packaging/rpm/rpmbuild/* ${DIR_DOCKER}
    rm -rf docker-ce-packaging

    if [[ ${CONTAINERD_VERS} != "0" ]]
    # CONTAINERD_VERS is equal to a version of containerd we want to build
    then
      echo ""
      echo "================================================="
      echo "==   Building containerd                         =="
      echo "================================================="
      
      DIR_CONTAINERD="/workspace/containerd-${CONTAINERD_VERS}"
      mkdir ${DIR_CONTAINERD}

      git clone https://github.com/docker/containerd-packaging.git

      pushd containerd-packaging

      DISTROS="${DEBS//-/:} ${RPMS//-/:}"

      for DISTRO in $DISTROS
      do
        make REF=${CONTAINERD_VERS} docker.io/library/${DISTRO}
      done

      popd

      cp -r containerd-packaging/build/* ${DIR_CONTAINERD}
      rm -rf containerd-packaging
    fi
  fi
fi
