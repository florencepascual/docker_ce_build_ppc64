#/bin/bash

if [[ ! -d docker-ce-packaging ]]
# if there is no docker-ce-packaging, git clone with depth 1
then
    echo "no docker-ce-packaging"
    git clone https://github.com/docker/docker-ce-packaging --depth 1
else
# if there is, update any changes
    cd docker-ce-packaging && git pull --depth 1 && cd ..
fi

if [[ ! -f env.list ]]
# if there is no env.list file, create the file
then
    echo "no env.list"
    touch env.list
else
# if there is already DEB_LIST or RPM_LIST, remove these lines
    if grep -Fq "DEB_LIST" env.list
    then
        echo "RPM LIST already"
        sed -i '/^RPM_LIST/d' env.list
        cat env.list
    elif grep -Fq "RPM_LIST" env.list
    then 
        echo "DEB_LIST already"
        sed -i '/^DEB_LIST/d' env.list
        cat env.list
    fi
fi

echo DEB_LIST=\"`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*`\" >> env.list
echo RPM_LIST=\"`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*`\" >> env.list

cat env.list
echo $DEB_LIST
echo $RPM_LIST


for PACKTYPE in DEB_LIST RPM_LIST; do
  echo "There is $PACKTYPE"

  for DISTRO in ${!PACKTYPE}; do

    echo "There is $DISTRO"
  done
done