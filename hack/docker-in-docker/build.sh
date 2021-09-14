#!/bin/bash

set -e

PATH_SCRIPTS="docker_ce_build_ppc64/hack/docker-in-docker"

sh ./${PATH_SCRIPTS}/dockerd-entrypoint.sh &
source /${PATH_SCRIPTS}/dockerd-starting.sh

set -o allexport
source env.list
source env-distrib.list

DIR_DOCKER="/workspace/docker-ce-${DOCKER_VERS}"

if [[ ${CONTAINERD_VERS} != "0" ]]
then
  DIR_CONTAINERD="/workspace/containerd-${CONTAINERD_VERS}"
fi
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

    ls ${DIR_DOCKER}/*
    if [[ $? -ne 0 ]]
    then
      # No packages built
      BOOL_DOCKER=0
    else
      # Packages built
      BOOL_DOCKER=1
    fi

    if [[ ${CONTAINERD_VERS} != "0" ]]
    # CONTAINERD_VERS is equal to a version of containerd we want to build
    then
      echo ""
      echo "================================================="
      echo "==   Building containerd                         =="
      echo "================================================="

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

      # check if packages have been built and stop the container
      ls ${DIR_CONTAINERD}/*
      if [[ $? -ne 0 ]]
      then
        # No packages built
        BOOL_CONTAINERD=0
      else
        # Packages built
        BOOL_CONTAINERD=1
      fi

      if [[ ${BOOL_DOCKER} -eq 0 ]] && [[ ${BOOL_CONTAINERD} -eq 0 ]]
      # if there is no packages built for docker and no packages built for containerd
      then
        echo "No packages built for docker and for containerd"
        kill -9 $pid && exit 1
      elif [[ ${BOOL_DOCKER} -eq 0 ]] || [[ ${BOOL_CONTAINERD} -eq 0 ]]
      # if there is no packages built for docker or no packages built for containerd
      then 
        echo "No packages built for either docker, or containerd"
        kill -9 $pid && exit 1
      elif [[ ${BOOL_DOCKER} -eq 1 ]] && [[ ${BOOL_CONTAINERD} -eq 1 ]]
      # if there are packages built for docker and packages built for containerd
      then
        echo "All packages built"
        kill -9 $pid && exit 0
      fi
    else
      # if CONTAINERD_VERS="0"
      echo $BOOL_DOCKER
      if [[ ${BOOL_DOCKER} -eq 0 ]]
      # if there is no packages built for docker and we did not build any containerd package
      then
        echo "No packages built for docker"
        kill -9 $pid && exit 1
      else
        echo "Packages built for docker"
        kill -9 $pid && exit 0
      fi
    fi
  fi
fi
