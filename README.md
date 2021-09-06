# Cook Book

## Steps

- Step 0 : Start a local web server
- Step 1 : Build containerd in a container
- Step 2 : Build docker_ce in a container
- Step 3 : Check the bundles in /home/aurelien/docker-ce/
- Step 4 : Push to /package2test dir for testing and update symbolic links
- Step 5 : Launch validation tests from a container
- Step 6 : Push to COS bucket
- Step 7 : Test stage - Run the test_distrib script


### Step 0 : Start a local web server for serving install packages and test suite
```
(cd /package2test/ && nohup python3 -m http.server 8080 > /home/aurelien/http_880.log  2>&1) &
```
### Step 1 : Build containerd in a container

#### Launch a container and connect through it
```
CONT_NAME=docker-build_local_containerd
docker run -d -v /home/aurelien/docker-ce:/docker-ce -v  /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME docker_ce_build
docker exec -it $CONT_NAME /bin/bash
```
#### Run the containerd script from github and pass the version we want to build (ie v1.4.6)
```
git clone https://github.com/alunsin/docker_ce_build_ppc64.git
SCRIPT='docker_ce_build_ppc64/build_containerd.sh v1.4.6';
DATE=`date +%d%m%y-%H%S`; export DATE && nohup bash -x  $SCRIPT> logs_$DATE.out 2>&1 & sleep 1; tail -f logs_$DATE.out
```

### Step 2 : Build docker_ce in a container

#### Launch a container and connect through it
```
CONT_NAME=docker-build_local_docker_ce
docker run -d -v /home/aurelien/docker-ce:/docker-ce -v  /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME docker_ce_build
docker exec -it $CONT_NAME /bin/bash
```
#### Run the docker_ce script from github and pass the version we want to build (ie v20.10.7)
```
#  #rm -rf cli docker-ce-packaging moby scan-cli-plugin
git clone https://github.com/alunsin/docker_ce_build_ppc64.git
```
Edit version of the docker_ce we want to build and commit tag/hash of docker-ce-packaging in build_docker-ce.sh as below:
- REF='v20.10.7'
- PACKAGING_REF='2455a897c45a7ab7f155950d3f69f28147c1526f'
```
DATE=`date +%d%m%y-%H%S`; export DATE && nohup bash -x docker_ce_build_ppc64/build_docker-ce.sh> logs_$DATE.out 2>&1 & sleep 1; tail -f logs_$DATE.out
```

### Step 3 : Check in /home/aurelien/docker-ce/ that the docker_ce directory contain the bundles for each distro and that containerd contain the deb and rpm files
```
cd /home/aurelien/docker-ce/docker-ce-050821-2011
find docker-ce-050821-2011
find docker-ce-050821-2011 | grep bundles 

cd /home/aurelien/docker-ce/containerd-050821-2142
find containerd-050821-2142
```

### Step 4 : Push to /package2test dir for testing and update symbolic links
```
sudo cp -r docker-ce-050821-2011 /package2test/
sudo rm  /package2test/docker-ce
sudo ln -s /package2test/docker-ce-050821-2011 /package2test/docker-ce

sudo cp -r containerd-050821-2142 /package2test/
sudo rm  /package2test/containerd
sudo ln -s /package2test/containerd-050821-2142 /package2test/containerd
```

### Step 5 : Launch validation tests from a container
```
CONT_NAME=docker-test_local_docker
docker run -d -v /home/aurelien/docker-ce:/docker-ce -v  /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME docker_ce_build
docker exec -it $CONT_NAME /bin/bash
git clone https://github.com/alunsin/docker_ce_build_ppc64.git
cd docker_ce_build_ppc64/test
```
#### Edit in the script which RPMS and DEBS
```
SCRIPT='test_distrib.sh';
DATE=`date +%d%m%y-%H%S`; export DATE && nohup bash -x  $SCRIPT> logs_$DATE.out 2>&1 & sleep 1; tail -f logs_$DATE.out
```
#### Get the results out of the container
```
mkdir /docker-ce/test_packages_$DATE
cp -r result logs_$DATE.out /docker-ce/test_packages_$DATE
```
#### Stop and Delete the container
```
docker stop $CONT_NAME && docker rm $CONT_NAME
```
#### Check log files



### Step 6 : Push to COS bucket

Requires s3fs >= 1.88, such as the one available from the debian:bullseye
```
CONT_NAME=docker_s3_copy
docker run -it -v /home/aurelien/docker-ce:/docker-ce -v /package2test:/package2test --privileged --name $CONT_NAME debian:bullseye bash
docker exec -it $CONT_NAME /bin/bash
apt update && apt install -y s3fs
```
#### Mount the s3fs
```
mkdir -p /mnt/s3_ibm-docker-builds
s3fs  ibm-docker-builds /mnt/s3_ibm-docker-builds -o url=https://s3.us-east.cloud-object-storage.appdomain.cloud -o passwd_file=/docker-ce/.s3fs_cos_secret -o ibm_iam_auth
```
#### Set the docker and containerd version without the last digit (patch number)
```
DOCKER_CE_VER="20.10"
CONTAINERD_VER="1.4"
```
#### Build tag is a manual increment (check in the s3fs directory)
```
DOCKER_CE_BUILD_TAG="4"
CONTAINERD_BUILD_TAG="4"

DOCKER_DIR="docker-ce-$DOCKER_CE_VER-$DOCKER_CE_BUILD_TAG"
CONTAINERD_DIR="containerd-$CONTAINERD_VER-$CONTAINERD_BUILD_TAG"
```
#### Prepare directories
```
echo creating directory $DOCKER_DIR
echo creating directory $CONTAINERD_DIR
mkdir $DOCKER_DIR
mkdir $CONTAINERD_DIR
```
#### Populating directories
```
cp /package2test/docker-ce/bundles-ce-* $DOCKER_DIR
cp -r /package2test/containerd/* $CONTAINERD_DIR
```
#### List content
```
find $DOCKER_DIR -type f
find $CONTAINERD_DIR -type f
```
#### Sanity cleanup , todo delete if  tar -tvzf returns empty file list
```
# tar -tvzf /package2test/docker-ce/bundles-ce-rhel-7-ppc64le.tar.gz | wc
rm docker-ce-20.10-4/bundles-ce-rhel-7-ppc64le.tar.gz
```
#### Copy to COS
```
cp -r $DOCKER_DIR $CONTAINERD_DIR /mnt/s3_ibm-docker-builds/
```

### Step 7 : Test stage - Run the test_distrib script
```
CONT_NAME=docker-test_staging_docker
docker run -d -v /home/aurelien/docker-ce:/docker-ce -v  /home/aurelien/docker-ce/.docker:/root/.docker --privileged  --name $CONT_NAME docker_ce_build
docker exec -it $CONT_NAME /bin/bash
git clone https://github.com/alunsin/docker_ce_build_ppc64.git
cd docker_ce_build_ppc64/test-staging
SCRIPT='test_distrib.sh';
```
#### Change args of docker_ce version and containerd version in the dockerfiles
```
DATE=`date +%d%m%y-%H%S`; export DATE && nohup bash -x  $SCRIPT> logs_$DATE.out 2>&1 & sleep 1; tail -f logs_$DATE.out
mkdir /docker-ce/test_packages_$DATE
cp -r result logs_$DATE.out  /docker-ce/test-staging_$DATE
```
---
### TODOS

Gobal:
 - add nohup + main logs inside scripts
 - add a script to push package to COS bucket using s3fs or curl?

 - Make the scripts have distros as input parameters to make it more flexible
 - Detect & build the list of ditros from a new script based on the docke_ce_package directory names
   - Detect changes in distro support (add /removal)
 - add time stamp

Build:
 - delete docker-ce tar.gz bundle file if content is empty 
 - Not sure why I am building dbgsym package for debian
   root@3f615f675e42:~# find $CONTAINERD_DIR -type f | grep -e dbg
     containerd-1.4-4/debian/bullseye/ppc64el/containerd.io-dbgsym_1.4.6-1_ppc64el.deb
     containerd-1.4-4/debian/buster/ppc64el/containerd.io-dbgsym_1.4.6-1_ppc64el.deb
Test
 - Copy result logs + main logs in a directory 'test_result_$DATE'
 - Replace local HTTP server for serving packages & test suite (github.ibm) by COS ?
 - Reword to avoid the 'error' for easy grep when this is not an error log
   - 'grepping potential errors' -> grepping for potential issue
 
Prow:
 - Dummy job to check that we can run in privileged mode and run Docker in Docker
 - Access COS [push secrets]

#### TODO calculate the new build tag to use from the existing dir

```
#cd /mnt/s3_ibm-docker-builds/
# Get current build tag for docker-ce
#LAST_BUILD_TAG=$(ls -d docker-ce-$DOCKER_CE_VER-* | sort --version-sort | tail -1| cut -d'-' -f4)
#NEXT_BUILD_TAG=$((LAST_BUILD_TAG+1))
#echo "$LAST_BUILD_TAG $NEXT_BUILD_TAG"
# Get current build tag for containerd
#LAST_BUILD_TAG=$(ls -d containerd-$DOCKER_CE_VER-* | sort --version-sort | tail -1| cut -d'-' -f3)
#NEXT_BUILD_TAG=$((LAST_BUILD_TAG+1))
#echo "$LAST_BUILD_TAG $NEXT_BUILD_TAG"
#cd --
```


## Automation

### Test

```
git pull https://github.com/florencepascual/test-infra-test 
kubectl delete pod/test-als-all-in-one-pod
kubectl apply -f test-infra-test/pod-dnd/pod-secret-s3-docker.yaml
kubectl exec -it pod/test-als-all-in-one-pod -- /bin/bash
```