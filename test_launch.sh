#/bin/bash
# launches test from the repo https://github.ibm.com/powercloud/dockertest

set -ue

. ./docker_ce_build_ppc64/dockerd-starting.sh

echo "Starting the docker test suite for:$1"
export GOPATH=${WORKSPACE}/dockertest:/go
export GO111MODULE=auto
cd /workspace/dockertest
make test WHAT="./tests/$1" GOFLAGS="-v"

echo "End of the docker test suite"