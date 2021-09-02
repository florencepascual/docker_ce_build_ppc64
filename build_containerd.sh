#/bin/bash


DATE=`date +%d%m%y-%H%S`
CONTAINERD_DIR="/docker-ce/containerd-$DATE"

if [ ! -d "$BUILD_OUT_DIR" ]; then
  mkdir $CONTAINERD_DIR
fi

# CONTAINERD_VERS, DEBS and RPMS

pushd containerd-packaging

DISTROS="${DEBS} ${RPMS}"

for DISTRO in $DISTROS
do
	make REF=${TAG} docker.io/library/$DISTRO
done

popd

cp -r containerd-packaging/build/* $CONTAINERD_DIR
