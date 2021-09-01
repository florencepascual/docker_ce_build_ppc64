#/bin/bash

if [[ ! -f env.list ]]
then
  DOCKER_VERS='v20.10.8'
  CONTAINERD_VERS='v1.4.9'
  PACKAGING_REF='5a28c77f52148f682ab1165dfcbbbad6537b148f'
else
  set -o allexport
  source env.list
fi

if [[ ! -f env-distrib.list ]]
then
  DEB_LIST="debian-bullseye debian-buster ubuntu-bionic ubuntu-focal ubuntu-groovy ubuntu-hirsute"
  RPM_LIST="centos-7 centos-8 fedora-33 fedora-34"
else
  set -o allexport
  source env-distrib.list
fi

DATE=`date +%d%m%y-%H%S`
DIR_DOCKER="/docker-ce-$DATE"
DIR_CONTAINERD="/containerd-$DATE"


echo ""
echo "================================================="
echo "==   Building docker-ce                         =="
echo "================================================="

mkdir $DIR_DOCKER

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

DIR_PACKAGING="docker-ce-packaging"

mkdir -p $DIR_PACKAGING
pushd $DIR_PACKAGING

git init
git remote add origin  https://github.com/docker/docker-ce-packaging.git
git fetch --depth 1 origin $PACKAGING_REF
git checkout FETCH_HEAD

make REF=$DOCKER_VERS checkout
popd

pushd docker-ce-packaging/deb
patchDockerFiles .
for DEB in $DEB_LIST
do
 echo ""
 echo "================================================="
 echo "==   Building for:$DEB                         =="
 echo "================================================="

 VERSION=$DOCKER_VERS make debbuild/bundles-ce-$DEB-ppc64le.tar.gz
done
popd

pushd docker-ce-packaging/rpm
patchDockerFiles .
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
 echo "==   Copying packages to $DIR_DOCKER        =="
 echo "================================================="

cp -r docker-ce-packaging/deb/debbuild/* $DIR_DOCKER
cp -r docker-ce-packaging/rpm/rpmbuild/* $DIR_DOCKER

 echo ""
 echo "================================================="
 echo "==   Building containerd                         =="
 echo "================================================="

mkdir $DIR_CONTAINERD

git clone https://github.com/docker/containerd-packaging.git

pushd containerd-packaging

DISTROS="${DEB_LIST//-/:} ${RPM_LIST//-/:}"

for DISTRO in $DISTROS
do
	make REF=${CONTAINERD_VERS} docker.io/library/${DISTRO}
done

popd

cp -r containerd-packaging/build/* $DIR_CONTAINERD
