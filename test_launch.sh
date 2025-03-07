#!/bin/bash
# script that launches tests from the repo https://github.ibm.com/powercloud/dockertest

set -ue

sh ${PATH_SCRIPTS}/dockerd-entrypoint.sh &
source ${PATH_SCRIPTS}/dockerd-starting.sh
docker version 2>&1 | tee -a ${PATH_TEST_ERRORS} 

echo "= Docker test suite for ${DISTRO_NAME} ="
export GOPATH=${WORKSPACE}/test:/go
export GO111MODULE=auto
cd /workspace/test/src/github.ibm.com/powercloud/dockertest
make test WHAT="./tests/${DISTRO_NAME}" GOFLAGS="-v"

echo "== End of the docker test suite =="

exit 0
