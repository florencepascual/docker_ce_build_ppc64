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

echo "building static"
pushd docker-ce-packaging/static
# get the latest version of runc
RUNC_VERS=$(eval "git ls-remote --refs --tags https://github.com/opencontainers/runc.git | cut --delimiter='/' --fields=3 | sort --version-sort | tail --lines=1")
echo "VERSION=${DOCKER_VERS} CONTAINERD_VERSION=${CONTAINERD_VERS} RUNC_VERSION=${RUNC_VERS} make static-linux" > ${PATH_SCRIPTS}/build_static.sh
chmod a+x ${PATH_SCRIPTS}/build_static.sh

docker run -d -v /home/fpascual/testing-prow-job/test-static:/workspace --privileged --env DOCKER_VERS --env CONTAINERD_VERS --env RUNC_VERS --name docker-build-static2 quay.io/powercloud/docker-ce-build /bin/bash -c '${PATH_SCRIPTS}/build_static.sh'

popd

cp docker-ce-packaging/static/build/linux/*.tgz ${DIR_DOCKER}

pushd ${DIR_DOCKER}
FILES="*"
for f in $FILES
do
  mv $f "${f//${DOCKER_VERS}/ppc64le}"
done
popd