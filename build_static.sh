#!/bin/bash
# Script building the static docker packages
# in the directory docker-ce-v20.10.9 where there is a static directory with the script
# docker run -d -v /home/fpascual/testing-prow-job:/workspace --privileged --name docker-build-static quay.io/powercloud/docker-ce-build
# docker exec -it docker-build-static /bin/bash
# ./static/build_static.sh
# docker run -d -v /home/fpascual/testing-prow-job:/workspace --env PATH_SCRIPTS --privileged --name docker-build-static quay.io/powercloud/docker-ce-build ./docker_ce_build_ppc64/build_static.sh

set -ue

set -o allexport
source env.list
source env-distrib.list

sh ${PATH_SCRIPTS}/dockerd-entrypoint.sh &
source ${PATH_SCRIPTS}/dockerd-waiting.sh

echo "building static"
pushd docker-ce-packaging/static
VERSION=${DOCKER_VERS} CONTAINERD_VERSION=v1.4.11 RUNC_VERSION=v1.0.2 make static-linux
popd