#/bin/bash

DOCKER_VERS='v20.10.8'
PACKAGING_REF='5a28c77f52148f682ab1165dfcbbbad6537b148f'
DATE=`date +%d%m%y-%H%S`
DOCKER_DIR="/docker-ce/docker-ce-$DATE"
CONTAINERD_DIR="/docker-ce/containerd-$DATE"

CONTAINERD_VERS='v1.4.9'


mkdir $DOCKER_DIR

# DOCKER_VERS, CONTAINERD_VERS, DEB_LIST and RPM_LIST

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
make REF=$DOCKER_VERS checkout
popd

echo "building debs"
pushd docker-ce-packaging/deb
patchDockerFiles .
DEB_LIST=`ls -1d debian-* ubuntu-*`
for DEB in $DEB_LIST
do
 echo ""
 echo "================================================="
 echo "==   Building for:$DEB                         =="
 echo "================================================="

 VERSION=$DOCKER_VERS make debbuild/bundles-ce-$DEB-ppc64le.tar.gz
done
popd

echo "building rpms"
pushd docker-ce-packaging/rpm
patchDockerFiles .
RPM_LIST=`ls -1d fedora-* centos-*`
for RPM in $RPM_LIST
do
 
 echo ""
 echo "================================================="
 echo "==   Building for:$RPM                         =="
 echo "================================================="
 
 VERSION=$DOCKER_VERS make rpmbuild/bundles-ce-$RPM-ppc64le.tar.gz
done
popd

 echo ""
 echo "================================================="
 echo "==   Copying packages to $DOCKER_DIR        =="
 echo "================================================="

cp -r docker-ce-packaging/deb/debbuild/* $DOCKER_DIR
cp -r docker-ce-packaging/rpm/rpmbuild/* $DOCKER_DIR

mkdir $CONTAINERD_DIR


git clone https://github.com/docker/containerd-packaging.git

pushd containerd-packaging

DISTROS="${DEB_LIST//-/:} ${RPM_LIST//-/:}"

for DISTRO in $DISTROS
do
	make REF=${CONTAINERD_VERS} docker.io/library/${DISTRO}
done

popd

cp -r containerd-packaging/build/* $CONTAINERD_DIR
