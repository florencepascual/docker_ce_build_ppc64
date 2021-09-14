#/bin/bash
# launches test from the repo https://github.ibm.com/powercloud/dockertest

set -ue

. ./docker_ce_build_ppc64/hack/docker-in-docker/dockerd-starting.sh

echo ${DISTRO_NAME}

if ! test -d /root/.docker
then
    mkdir /root/.docker
    echo "${SECRET_AUTH}" > /root/.docker/config.json
fi

echo "Starting the docker test suite for:${DISTRO_NAME}"
export GOPATH=${WORKSPACE}/test:/go
export GO111MODULE=auto
cd /workspace/test/src/github.ibm.com/powercloud/dockertest
make test WHAT="./tests/${DISTRO_NAME}" GOFLAGS="-v"

echo "End of the docker test suite"

exit 0